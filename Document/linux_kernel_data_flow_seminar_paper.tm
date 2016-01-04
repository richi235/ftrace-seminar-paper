<TeXmacs|1.99.3>

<style|<tuple|llncs|british|framed-theorems>>

<\body>
  <\hide-preamble>
    \;

    <assign|item*|<macro|name|<render-item|<arg|name>><with|index-enabled|false|<set-binding|<arg|name>>>>>

    <assign|description|<\macro|body>
      <list|<macro|name|<compact-item|<item-strong|<arg|name>:
      >>>|<macro|name|<with|mode|math|<with|font-series|bold|math-font-series|bold|<rigid|\<ast\>>>>>|<arg|body>>
    </macro>>

    <assign|description-long|<\macro|body>
      <list|<macro|name|<item-long|<no-indent><move|<item-strong|<arg|name>>|-1.5fn|0fn>>>|<macro|name|<with|mode|math|<with|font-series|bold|math-font-series|bold|<rigid|\<ast\>>>>>|<arg|body>>
    </macro>>

    <assign|bibliography-text|<macro|<localize|Bibliography>>>
  </hide-preamble>

  <\doc-data|<doc-title|Tracing the Way of Data in a TCP Connection through
  the Linux Kernel>|<doc-subtitle|Seminar Organic
  Computing>|<doc-running-title|>||<doc-running-title|aa>>
    \;
  </doc-data>

  \;

  \;

  \;

  <\with|par-mode|center>
    <name|Richard Sailer>

    Matrikelnummer: 1192352

    \;

    Universit�t Augsburg

    Lehrstuhl f�r Organic Computing

    richard.willi.sailer@student.uni-augsburg.de
  </with>

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  \;

  <abstract-data|<abstract|TODO>>

  Copyright <copyright> 2016 Richard Sailer.\ 

  Permission is granted to copy, distribute and/or modify this document under
  the terms of the <em|GNU Free Documentation License> (<em|GFDL>), Version
  1.3.

  <new-page>

  <section|Motivation and Introduction>

  Linux kernel programming is complex and difficult for most students or
  people with experience in application programming. The C programming
  language lacks many of the high level features these people are used to and
  even common C libraries are not accessible in kernel code, actually no C
  libraries at all is available in kernel space<cite|love2010linux>.\ 

  Aditionally the kernel is a complex piece of software consisting of many
  modules working together in non-trivial ways. To change or extend a part of
  the kernel semantic knowledge on how and why this parts work together is
  necesarry.

  While the first two obstacles, the often unfamiliar C programming language
  and the lack of libraries, can be overcome with some experience and get
  smaller and smaller after some time, the possibility of understanding the
  in-kernel mechanics is an question of good documentation.

  While there exist several good books on this topic, all of them have one of
  the following three problems:

  <\enumerate>
    <item>They grow old very fast

    Or put another way: The linux kernel evolves too fast. For example
    <name|Understanding Linux Network Internals> by Christian
    Benvenuti<cite|benvenuti2006>, a really comprehensive books, was written
    in 2006 covering linux kernel 2.6. Since it took some time writing some
    examples and parts cover even older parts, like the bottom halve interupt
    handling. Many details in the tcp stack or the interupt handling have
    changed since. At the time of writing the current version of the linux
    kernel is 4.3

    <item>They have a certain focus and do preselection of content

    Since the linux kernel is a very large project consisting of over 19
    Million lines of code<\footnote>
      Version 4.1, see http://www.phoronix.com/scan.php?page=news_item&px=Linux-19.5M-Stats
      for details.
    </footnote> obviously a preselection is necesarry even if the author is
    focussing on a subsystem. For example in \PLinux Kernel Networking\Q by
    Rami Rosen<cite|rosen2013linux> TCP is covered quite brief since the
    lower networking layers get a much deeper coverage.

    <item>They are not freely available

    Most of these books have to be purchased and ordered. Some of them are
    quite expensive and ordering them can take several days. These two facts
    make it more difficult for interested programmers to start linux kernel
    programming.
  </enumerate>

  This seminar paper tries to solve two of these three issues. In this paper
  we will try to provide an free (licensed under the GNU Free Documentation
  License) and up to date overview of one very specific topic: The Way of
  Data in a TCP Connection through the Linux kernel. Aditionally we will
  introduce and explain the method used to examine and understand these
  kernel mechanics in order to give every reader a tool helpful in
  understanding other parts of the kernel his or herself.

  <section|State of Research and Related Work>

  There are several papers and linux kernel documentation documents covering
  related or similiar topics. This section tries to list the most important
  ones and will explain the similiarities and differences in scope, focus,
  and other aspects compared to this seminar paper.

  <subsection|The performance analysis of Linux networking--packet
  receiving<cite|wu2007performance>>

  This work done in 2006 by Wenji Wu and Matt Crawford from the fermilab in
  Illinois, USA focuses entirely on the packet recieve process and
  performance issues. While providing many valuable insights for performance
  engineering and answering some on the \Ptracing the way of data\Q questions
  on this work it barely covers the \Pwhich function are involved and what
  are they doing\Q-question, which is part of the focus in this work, since
  their primary target was performance optimization. Also it contains the
  following diagram of the buffer structure, which is quite helpful for
  getting an overview and context for the results of the next chapters:

  <big-figure|<image|Bilder/Buffers_kleiner.png|526px|137px||>|<label|fig_buffers>Buffers
  and Copying in the Linux Kernel>

  The 2 Buffers shown in Figure <reference|fig_buffers> will appear again in
  the results section.

  <subsection|The \Pkernel_flow\Q article in the official Linux Fundation
  Documentation<\footnote>
    See: http://www.linuxfoundation.org/collaborate/workgroups/networking/kernel_flow
    or use <hlink|pdf-href|http://www.linuxfoundation.org/collaborate/workgroups/networking/kernel_flow>
  </footnote>>

  In 2009 the linux foundation realeased this documentation for the linux
  kernel networking stack together with a quite tall and comprehensive
  diagram (which for layouting and scope reasons is not included in this
  paper). With a size of 3489x1952 pixels even on a full HD monitor it's not
  possible to look at the full diagram. Besides it suffers from \Pputting
  absolutely everything in one picture\Q which makes it difficult to get an
  overview. While beeing an primary and valuable source for this work it was
  a goal of this paper to produce an up-to-date and simplified version of
  this diagram as poster. Simplified in this case means, split into two
  distinct diagrams one for the receive path and one for the send path.

  <section|About the Measuring Method: ftrace>

  <subsection|About ftrace>

  <subsubsection|What is tracing and ftrace>

  Ftrace is a kernel-builtin tracer for function calls and events inside the
  linux kernel.<cite|ftrace-linux>

  <\definition*>
    tracer (software engineering) <cite|Kraft1911>

    A tracer is a tool for analyzing the behaviour of a given software at
    runtime. It provides an output similiar to an log of what happens inside
    the program. In most cases this output is an sequential structured list
    of all function calls which happened during execution. But there also
    exist other kinds of tracing like events tracing or I/O tracing. For
    VM-languages like Java or C# tracing is an feature of the runtime
    environment which can be turned on or off at runtime. For compiled
    languages like C tracing support has to be added via compiler switches or
    additional modules.
  </definition*>

  \;

  In the case of ftrace the tracing support is part of the software, the
  linux kernel. On most architectures ftrace uses hardware support for better
  performance.<cite|ftrace-design-linux>

  <subsubsection|A Short Overview of ftrace Capabilities and Usage>

  ftrace is used and configured via the <em|debugfs> virtual filesystem. With
  the following shell command <em|debugfs> is made available:

  Ftrace can be used via the <em|trace-cmd> programm. <em|trace-cmd> is
  packad and available in all big linux distributions.<\footnote>
    At the time of this writing (03.01.2016) <em|trace-cmd> is available in
    Ubuntu (since 12.04), Debian testing and stable and Fedora.
  </footnote> Since tracing in kernel operation is still a quite major
  intervention into a running system only the root user is allowed to use
  trace-cmd, so all the following examples have to be executed as root.

  To simply start recording all the function calls happening in the linux
  without any filtering use:

  <big-figure|<verbatim|trace-cmd record -p function_graph >|Example: Start
  tracing of all function calls in linux kernel>

  This writes all the results into a trace.dat in your working directory.
  <verbatim|record> is one of the several subcommands of trace-cmd, in our
  examples and later measurments only the <verbatim|record> and the
  <verbatim|report> subcommands are needed. You shouldn't run this command
  (in the unfiltered version) too long, since it produces quite big files,
  about 900 MB after 30 seconds of tracing appeared in all tests using
  unfiltered tracing.

  To view the content of the <verbatim|trace.dat> file in a human readable
  format use:\ 

  <big-figure|<verbatim|trace-cmd report \<gtr\> results>|Converting the
  Results into an humen readable format.>

  The report subcommands automatically uses the trace.dat file in the working
  directory and writes it's content to STDOUT which the redirection operator
  redirects to the <verbatim|results> file.

  The human readable output contains several columns about: the name of the
  process on behalf of the in kernel function call happened, the id of the
  CPU, an absolute timestamp, info if it's a function exit or entry event,
  the time the function needed (most below one micro-second) and the function
  name. The function names are graphically indentend to display the call
  hierarchy, so if <em|B> is called by <em|A>, \ <em|B> is indented relative
  to <em|A> by 2 spaces.

  Usually these are much more columns than needed so in the results you will
  see in these paper, some of these columns were removed for layouting
  reasons.

  <subsubsection|Filtering>For analyzing the way of data of a TCP connection
  we do not need information of all functions called in the overall kernel.
  We're only interested in traceing of the function calls happening on behalf
  of one single application. Kernel side filtering after a specific pid is
  possible using:

  \;

  <big-figure|<verbatim|trace-cmd -p function_graph -P
  \<less\>pid\<gtr\>>|Tracing all in-kernel function callls happening on
  behalf of \<less\>pid\<gtr\>>

  This way, the log file sizes are much smaller and more focused than
  previously. Tracing netcat for some time, while sending and recieving 3
  small text messages produced a trace log file of 2,3 MB.

  <subsection|Why ftrace? Comparison to other Measurment Methods>

  Why did we choose ftrace? There are several tools for analysing and
  understing what happens inside the linux kernel.\ 

  <section|Test Setup and Results>

  <subsection|Test Setup>

  To produce measurable network traffic the <em|BSD netcat> programm has been
  used. Netcat is a small unix command line programm which opens a TCP (or
  UDP or Unix Domain) Socket, either as listening socket, or as \Pclient\Q to
  connect to another socket. The IP and Port to connect to (or the port to
  listen on) are supplied as command line parameters. For example:
  <verbatim|nc 17.17.17.17 1055> connects to the IP 17.17.17.17 on port 1055
  via an IPv4 TCP connection. Complementary with <verbatim|nc -l 1055> the
  process opens an listening socket on the local machine on port 1055,
  waiting for a IPv4 TCP connection. After establishing a connection netcat
  sends all data it gets from STDIN through the socket and prints all data it
  recieves through the socket to STDOUT.

  For this experiment 2 netcat instances were used, one on the measurment
  computer another on an remote linux server. The command used on the
  measurment computer was <verbatim|nc -l 1337> and the remote server
  connected via <verbatim|nc \<less\>ip\<gtr\> 1337>. After the connection
  was established in another terminal tracing was started using:

  <center|<verbatim|trace-cmd record -p function_graph -P
  \<less\>nc-pid\<gtr\>>>

  Then two short messages (strings of 9 Byte and 167 Byte) were sent from the
  measurement computer. Following two messages of equal size were sent from
  the remote server and recieved by the measurement computer. Finalizing the
  tracing was stopped and the results translated into a human readable file
  using <verbatim|trace-cmd report>.

  <subsection|Test results>

  Since the full trace of all function calls happening on behalf of netcat
  contained about 3000 lines (which subtracting all the empty lines drawn for
  the ascii art graph and closing brackets are about 2100 function calls),
  post editing got necesarry. Most of the function calls involved scheduling,
  terminal I/O or kernel internal locking of resources, so the sequences
  belonging to sending or recieving one packet were located and extracted.
  This happened by following the <verbatim|SyS_write()> and
  <verbatim|sys_read()> calls, which are the syscalls netcat uses to send and
  receive packets. This was gathered through traceing all the syscalls netcat
  does using strace.\ 

  The receive sequence consisted of 37 function calls and 56 lines which is
  small enough to print the complete trace in this document. Contrastingly
  the send sequence comprised 510 lines, so shortening got necesarry. The
  shortening included removing most of the locking and mutex function calls.
  Also in many cases where <verbatim|function()> , did some locking and then
  called <verbatim|__function()> for doing the internal work were simplified
  by only keeping the <verbatim|function()> call. As a last step, the
  indentation and superflous columns of both results were removed, so both
  traces fit into this document side by side.\ 

  The final simplified traces are visible in Figure <reference|send-trace>
  and Figure <reference|recv-trace>. The full and unedited trace results are
  available via \ 

  <\with|par-columns|2>
    <big-figure|<\verbatim>
      SyS_write() {

      __fdget_pos() [...]

      vfs_write() {

      rw_verify_area() [...]

      __vfs_write() {

      sock_write_iter() {

      sock_sendmsg() {

      inet_sendmsg() {

      tcp_sendmsg() {

      lock_sock_nested() [...]

      tcp_send_mss() [...]

      sk_stream_alloc_skb() [...]

      skb_entail() [...]

      skb_put();

      tcp_push() {

      __tcp_push_pending_frames() {

      tcp_write_xmit() {

      tcp_init_tso_segs();

      tcp_transmit_skb() {

      skb_clone() [...]

      skb_push();

      tcp_v4_send_check() [...]

      bictcp_cwnd_event();

      ip_queue_xmit() {

      skb_push();

      ip_local_out_sk() {

      __ip_local_out_sk() {

      ip_send_check();

      nf_hook_slow() [...]

      ip_output() {

      nf_hook_slow() [...]

      ip_finish_output() {

      ip_finish_output2() {

      skb_push();

      dev_queue_xmit_sk() {

      __dev_queue_xmit() {

      skb_clone() {

      kmem_cache_alloc();

      __skb_clone() {

      __copy_skb_header();

      skb_release_all() {

      skb_release_head_state();

      skb_release_data();

      kfree_skbmem()\ 

      kmem_cache_free();

      e1000_xmit_frame() [...]

      } } } } } } }

      tcp_event_new_data_sent() {

      tcp_rearm_rto() {

      tcp_rearm_rto.part.59() {

      sk_reset_timer() {

      mod_timer() [...]

      } } } } } }

      release_sock() {

      } } } }

      fsnotify();

      } }
    </verbatim>|<label|send-trace>Sending a TCP packet, simplified kernel
    trace result>

    <\big-figure>
      <\verbatim>
        sys_read() {

        __fdget_pos() {

        __fget_light();

        }

        vfs_read() {

        rw_verify_area() {

        security_file_permission() {

        __fsnotify_parent();

        fsnotify();

        }

        }

        __vfs_read() {

        sock_read_iter() {

        sock_recvmsg() {

        security_socket_recvmsg();

        inet_recvmsg() {

        tcp_recvmsg() {

        lock_sock_nested() {

        _cond_resched();

        _raw_spin_lock_bh();

        __local_bh_enable_ip();

        }

        skb_copy_datagram_iter();

        tcp_rcv_space_adjust();

        __kfree_skb() {

        skb_release_all() {

        skb_release_head_state() {

        sock_rfree();

        }

        skb_release_data() {

        kfree();

        }

        }

        kfree_skbmem() {

        kmem_cache_free();

        }

        }

        tcp_cleanup_rbuf() {

        __tcp_select_window();

        }

        release_sock() {

        _raw_spin_lock_bh();

        tcp_release_cb();

        _raw_spin_unlock_bh() {

        __local_bh_enable_ip();

        }

        }

        }

        }

        }

        }

        }

        __fsnotify_parent();

        fsnotify();

        }

        }
      </verbatim>
    </big-figure|<label|recv-trace>Receiving a TCP packet complete kernel
    trace results>
  </with>

  <section|Evaluation and Discussion of the Results>

  <subsection|Send Flow>

  Asuming a TCP connection is already established and we have a socket for
  sending data in our programm. Before the TCP implementation of the kernel
  can process and send the data, it has to get the data from userspace, the
  next two subsections will cover how this handing over happens and how the
  kernel will process the data.

  <subsubsection|Syscalls and Kernel Entry>

  There are 4<\footnote>
    Actually there are 6, but <verbatim|writev()> and <verbatim|fwrite()> are
    not mentioned seperately because from a kernel developer point of view
    they are similiar to the discussed ones. (See main text, below
    enumeration).
  </footnote> syscalls available for sending data through a TCP socket,
  namely:

  <\with|par-columns|2>
    <\itemize>
      <item>write()

      <item>send()

      <item>sendto()

      <item>sendmsg()
    </itemize>
  </with>

  They all need a file handle to the socket and a pointer to the
  send-data-buffer as arguments. They differ in the number of additional
  parameters and the fact that sendmsg() needs a more complex
  <verbatim|msghdr> data structure for the input data instead of a simple
  buffer.\ 

  <subsubsection|In Kernel Flow>

  <subsection|Recieve Flow>

  <subsubsection|Syscalls and Kernel Entry>

  From userspace there are several entry points to the kernel for recieving
  data:

  <\with|par-columns|2>
    <\itemize>
      <item>read()

      <item>recv()

      <item>recvfrom()

      <item>recvmsg()
    </itemize>
  </with>

  <subsubsection|In Kernel Flow>

  <section|Conclusion>

  The two goals of this work were reached. This text contains an freely
  available and up to date overview over the linux TCP networking internals
  and the ftrace kernel event tracing toolkit. Regarding the third issue, the
  scope, we tried give a quite general scope, covering no part of the TCP
  stack explicitely (or solely sending/recieving), so every ascending kernel
  developer gets some general context of the part functioniality he or she
  wants to change or improve. Nevertheless TCP Networking is already a quite
  focused topic, so the third issue was not completely solved.

  Concerning the decision for using ftrace it must be said that using ftrace
  solely was no very good idea, since ftrace (or trace-cmd) can not report
  any information about the function parameters used.<\footnote>
    There exists no option or capability in the ftrace documentation
    regarding function parameters.
  </footnote><cite|ftrace-linux> But knowing what data a function is using
  (or what pointers to data) is quite important for tracing the way of data.
  So a combined method of using ftrace and looking up function prototypes in
  the linux source code was employed and worked fairly well.

  So for generally understanding how these functions work together ftrace and
  prototype lookup is a reasonable method. But if the goal is fixing errors
  and knowledge about the concrete values passed to a function get necessary
  other tools like <em|kgdb> and <em|systemtap> are more well-suited.

  <new-page>

  <\bibliography|bib|tm-plain|bibliography.bib>
    <\bib-list|7>
      <bibitem*|1><label|bib-benvenuti2006>Christian Benvenuti.<newblock>
      <with|font-shape|italic|Understanding Linux network
      internals>.<newblock> O'Reilly, Sebastapol, Calif, 2006.<newblock>

      <bibitem*|2><label|bib-Kraft1911>Johan Kraft, Anders Wall<localize|,
      and >Holger Kienle.<newblock> Trace recording for embedded systems:
      lessons learned from five industrial projects.<newblock> <localize|In
      ><with|font-shape|italic|Proceedings of the First International
      Conference on Runtime Verification (RV 2010)>. Springer-Verlag (Lecture
      Notes in Computer Science), November 2010.<newblock> Original
      publication is available at www.springerlink.com.<newblock>

      <bibitem*|3><label|bib-love2010linux>Robert Love.<newblock>
      <with|font-shape|italic|Linux kernel development>.<newblock>
      Addison-Wesley, Upper Saddle River, NJ, 2010.<newblock>

      <bibitem*|4><label|bib-ftrace-design-linux>Mike<nbsp>Frysinger
      .<newblock> Function tracer guts.<newblock> Doc-file in Linux source
      tree: linux/Documentation/trace/ftrace-design.txt.<newblock>

      <bibitem*|5><label|bib-rosen2013linux>R.<nbsp>Rosen.<newblock>
      <with|font-shape|italic|Linux Kernel Networking: Implementation and
      Theory>.<newblock> Books for professionals by professionals. Apress,
      2013.<newblock>

      <bibitem*|6><label|bib-ftrace-linux>Steven<nbsp>Rostedt .<newblock>
      Ftrace - function tracer.<newblock> Doc-file in Linux source tree:
      linux/Documentation/trace/ftrace.txt.<newblock>

      <bibitem*|7><label|bib-wu2007performance>Wenji Wu, Matt
      Crawford<localize|, and >Mark Bowden.<newblock> The performance
      analysis of linux networking\Upacket receiving.<newblock>
      <with|font-shape|italic|Computer Communications>, 30(5):1044\U1057,
      2007.<newblock>
    </bib-list>
  </bibliography>
</body>

<\initial>
  <\collection>
    <associate|page-medium|paper>
    <associate|page-screen-margin|false>
    <associate|par-columns|1>
    <associate|preamble|false>
  </collection>
</initial>

<\attachments>
  <\collection>
    <\associate|bib-bibliography>
      <\db-entry|+HwYzixBDVcj5K3|book|love2010linux>
        <db-field|contributor|richi>

        <db-field|modus|imported>

        <db-field|date|1448883688>
      <|db-entry>
        <db-field|author|Robert <name|Love>>

        <db-field|title|Linux kernel development>

        <db-field|publisher|Addison-Wesley>

        <db-field|year|2010>

        <db-field|address|Upper Saddle River, NJ>

        <db-field|isbn|978-0672329463>
      </db-entry>

      <\db-entry|+HwYzixBDVcj5K4|book|benvenuti2006>
        <db-field|contributor|richi>

        <db-field|modus|imported>

        <db-field|date|1448885760>
      <|db-entry>
        <db-field|author|Christian <name|Benvenuti>>

        <db-field|title|Understanding Linux network internals>

        <db-field|publisher|O'Reilly>

        <db-field|year|2006>

        <db-field|address|Sebastapol, Calif>

        <db-field|isbn|978-0596002558>
      </db-entry>

      <\db-entry|+FRCTJ7uPE2eqFS|book|rosen2013linux>
        <db-field|contributor|richi>

        <db-field|modus|imported>

        <db-field|date|1451815582>
      <|db-entry>
        <db-field|author|R. <name|Rosen>>

        <db-field|title|Linux Kernel Networking: Implementation and Theory>

        <db-field|publisher|Apress>

        <db-field|year|2013>

        <db-field|series|Books for professionals by professionals>

        <db-field|isbn|9781430261964>

        <db-field|url|https://books.google.de/books?id=96V4AgAAQBAJ>
      </db-entry>

      <\db-entry|+UI30lmjpi2qkC4|article|wu2007performance>
        <db-field|contributor|richi>

        <db-field|modus|imported>

        <db-field|date|1451534852>
      <|db-entry>
        <db-field|author|Wenji <name|Wu><name-sep>Matt
        <name|Crawford><name-sep>Mark <name|Bowden>>

        <db-field|title|The performance analysis of linux networking\Upacket
        receiving>

        <db-field|journal|Computer Communications>

        <db-field|year|2007>

        <db-field|volume|30>

        <db-field|number|5>

        <db-field|pages|1044\U1057>

        <db-field|publisher|Elsevier>
      </db-entry>

      <\db-entry|+DOFjyv9YwrAHfy|misc|ftrace-linux>
        <db-field|newer|+DOFjyv9YwrAHfw>

        <db-field|contributor|richi>

        <db-field|modus|imported>

        <db-field|date|1448786418>
      <|db-entry>
        <db-field|author|Steven Rostedt>

        <db-field|title|Ftrace - function tracer>

        <db-field|howpublished|Doc-file in Linux source tree:
        linux/Documentation/trace/ftrace.txt>

        <db-field|url|https://www.kernel.org/doc/Documentation/trace/ftrace.txt>
      </db-entry>

      <\db-entry|+DOFjyv9YwrAHg0|inproceedings|Kraft1911>
        <db-field|contributor|richi>

        <db-field|modus|imported>

        <db-field|date|1448787119>
      <|db-entry>
        <db-field|author|Johan <name|Kraft><name-sep>Anders
        <name|Wall><name-sep>Holger <name|Kienle>>

        <db-field|title|Trace recording for embedded systems: lessons learned
        from five industrial projects>

        <db-field|booktitle|Proceedings of the First International Conference
        on Runtime Verification (RV 2010)>

        <db-field|year|2010>

        <db-field|month|November>

        <db-field|publisher|Springer-Verlag (Lecture Notes in Computer
        Science)>

        <db-field|note|Original publication is available at
        www.springerlink.com>

        <db-field|url|<slink|http://www.es.mdh.se/publications/1911->>
      </db-entry>

      <\db-entry|+DOFjyv9YwrAHfz|misc|ftrace-design-linux>
        <db-field|newer|+DOFjyv9YwrAHfx>

        <db-field|contributor|richi>

        <db-field|modus|imported>

        <db-field|date|1448786418>
      <|db-entry>
        <db-field|author|Mike Frysinger>

        <db-field|title|Function tracer guts>

        <db-field|howpublished|Doc-file in Linux source tree:
        linux/Documentation/trace/ftrace-design.txt>

        <db-field|url|https://www.kernel.org/doc/Documentation/trace/ftrace-design.txt>
      </db-entry>
    </associate>
  </collection>
</attachments>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|2>>
    <associate|auto-10|<tuple|2|4>>
    <associate|auto-11|<tuple|3|4>>
    <associate|auto-12|<tuple|3.1.3|5>>
    <associate|auto-13|<tuple|4|5>>
    <associate|auto-14|<tuple|3.2|5>>
    <associate|auto-15|<tuple|4|5>>
    <associate|auto-16|<tuple|4.1|5>>
    <associate|auto-17|<tuple|4.2|5>>
    <associate|auto-18|<tuple|5|6>>
    <associate|auto-19|<tuple|6|6>>
    <associate|auto-2|<tuple|2|3>>
    <associate|auto-20|<tuple|5|7>>
    <associate|auto-21|<tuple|5.1|7>>
    <associate|auto-22|<tuple|5.1.1|7>>
    <associate|auto-23|<tuple|5.1.2|7>>
    <associate|auto-24|<tuple|5.2|7>>
    <associate|auto-25|<tuple|5.2.1|7>>
    <associate|auto-26|<tuple|5.2.2|7>>
    <associate|auto-27|<tuple|6|9>>
    <associate|auto-28|<tuple|7|8>>
    <associate|auto-29|<tuple|6|8>>
    <associate|auto-3|<tuple|2.1|3>>
    <associate|auto-30|<tuple|6|8>>
    <associate|auto-31|<tuple|6|8>>
    <associate|auto-32|<tuple|6|8>>
    <associate|auto-33|<tuple|6|8>>
    <associate|auto-34|<tuple|5.2.2|8>>
    <associate|auto-35|<tuple|6|9>>
    <associate|auto-36|<tuple|6|11>>
    <associate|auto-37|<tuple|6|12>>
    <associate|auto-38|<tuple|6|12>>
    <associate|auto-39|<tuple|6|14>>
    <associate|auto-4|<tuple|1|3>>
    <associate|auto-5|<tuple|2.2|3>>
    <associate|auto-6|<tuple|3|4>>
    <associate|auto-7|<tuple|3.1|4>>
    <associate|auto-8|<tuple|3.1.1|4>>
    <associate|auto-9|<tuple|3.1.2|4>>
    <associate|bib-Kraft1911|<tuple|2|9>>
    <associate|bib-benvenuti2006|<tuple|1|9>>
    <associate|bib-chimata2005path|<tuple|2|12>>
    <associate|bib-ftrace-design-linux|<tuple|4|9>>
    <associate|bib-ftrace-linux|<tuple|6|9>>
    <associate|bib-love2010linux|<tuple|3|9>>
    <associate|bib-man-tcp|<tuple|1|4>>
    <associate|bib-rosen2013linux|<tuple|5|9>>
    <associate|bib-tuntap-linux|<tuple|2|4>>
    <associate|bib-wu2007performance|<tuple|7|9>>
    <associate|fig_buffers|<tuple|1|3>>
    <associate|figure_3|<tuple|4|7>>
    <associate|footnote-1|<tuple|1|2>>
    <associate|footnote-2|<tuple|2|6>>
    <associate|footnote-3|<tuple|3|9>>
    <associate|footnote-4|<tuple|4|3>>
    <associate|footnote-5|<tuple|5|4>>
    <associate|footnote-6|<tuple|6|7>>
    <associate|footnote-7|<tuple|7|8>>
    <associate|footnr-1|<tuple|1|2>>
    <associate|footnr-2|<tuple|2|6>>
    <associate|footnr-3|<tuple|3|9>>
    <associate|footnr-4|<tuple|4|3>>
    <associate|footnr-5|<tuple|5|4>>
    <associate|footnr-6|<tuple|6|7>>
    <associate|footnr-7|<tuple|7|8>>
    <associate|recv-trace|<tuple|6|?>>
    <associate|send-trace|<tuple|5|?>>
  </collection>
</references>

<\auxiliary>
  <\collection>
    <\associate|bib>
      love2010linux

      benvenuti2006

      rosen2013linux

      wu2007performance

      ftrace-linux

      Kraft1911

      ftrace-design-linux

      ftrace-linux
    </associate>
    <\associate|figure>
      <tuple|normal|Buffers and Copying in the Linux Kernel|<pageref|auto-4>>

      <tuple|normal|Example: Start tracing of all function calls in linux
      kernel|<pageref|auto-10>>

      <tuple|normal|Converting the Results into an humen readable
      format.|<pageref|auto-11>>

      <tuple|normal|Tracing all in-kernel function callls happening on behalf
      of \<less\>pid\<gtr\>|<pageref|auto-13>>

      <tuple|normal|Sending a TCP packet, simplified kernel trace
      result|<pageref|auto-18>>

      <tuple|normal|Receiving a TCP packet complete kernel trace
      results|<pageref|auto-19>>
    </associate>
    <\associate|toc>
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|1<space|2spc>Motivation
      and Introduction> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|2<space|2spc>State
      of Research and Related Work> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <with|par-left|<quote|1tab>|2.1<space|2spc>The performance analysis of
      Linux networking--packet receiving[<write|bib|wu2007performance><reference|bib-wu2007performance>]
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3>>

      <with|par-left|<quote|1tab>|2.2<space|2spc>The \Pkernel_flow\Q article
      in the official Linux Fundation Documentation<assign|footnote-nr|2><hidden|<tuple>><\float|footnote|>
        <with|font-size|<quote|0.771>|<with|par-mode|<quote|justify>|par-left|<quote|0cm>|par-right|<quote|0cm>|font-shape|<quote|right>|dummy|<quote|<macro|<tex-footnote-sep>>>|dummy|<quote|<macro|<tex-footnote-tm-barlen>>>|<\surround|<locus|<id|%3FB69D8-4A1BF48>|<link|hyperlink|<id|%3FB69D8-4A1BF48>|<url|#footnr-2>>|2>.
        |<hidden|<tuple|footnote-2>><htab|0fn|first>>
          See: http://www.linuxfoundation.org/collaborate/workgroups/networking/kernel_flow
          or use <locus|<id|%3FB69D8-4A1BEA0>|<link|hyperlink|<id|%3FB69D8-4A1BEA0>|<url|http://www.linuxfoundation.org/collaborate/workgroups/networking/kernel_flow>>|pdf-href>
        </surround>>>
      </float><space|0spc><rsup|<with|font-shape|<quote|right>|<reference|footnote-2>>>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|3<space|2spc>About
      the Measuring Method: ftrace> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>

      <with|par-left|<quote|1tab>|3.1<space|2spc>About ftrace
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7>>

      <with|par-left|<quote|2tab>|3.1.1<space|2spc>What is tracing and ftrace
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8>>

      <with|par-left|<quote|2tab>|3.1.2<space|2spc>A Short Overview of ftrace
      Capabilities and Usage <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9>>

      <with|par-left|<quote|2tab>|3.1.3<space|2spc>Filtering
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12>>

      <with|par-left|<quote|1tab>|3.2<space|2spc>Why ftrace? Comparison to
      other Measurment Methods <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-14>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|4<space|2spc>Measurment
      and Results> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-15><vspace|0.5fn>

      <with|par-left|<quote|1tab>|4.1<space|2spc>Test Setup
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-16>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|5<space|2spc>Results>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-17><vspace|0.5fn>

      <with|par-left|<quote|1tab>|5.1<space|2spc>Send Flow
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-20>>

      <with|par-left|<quote|2tab>|5.1.1<space|2spc>Syscalls and Kernel Entry
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-21>>

      <with|par-left|<quote|2tab>|5.1.2<space|2spc>In Kernel Flow
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-22>>

      <with|par-left|<quote|1tab>|5.2<space|2spc>Recieve Flow
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-23>>

      <with|par-left|<quote|2tab>|5.2.1<space|2spc>Syscalls and Kernel Entry
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-24>>

      <with|par-left|<quote|2tab>|5.2.2<space|2spc>In Kernel Flow
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-25>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|6<space|2spc>Conclusion>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-26><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Bibliography>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-27><vspace|0.5fn>
    </associate>
  </collection>
</auxiliary>