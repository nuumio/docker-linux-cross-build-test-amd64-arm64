# WARNING

**This test may corrupt or delete your data and render your system useless!** Run it at your own risk!

The worst that has happened to me so far is **root filesystem corruption** that required manual fixing of it with `fsck` to make the system bootable again. If you have no idea what I'm talking about here it's better you don't even try running this.

I've only tested this in Ubuntu 18.04 running natively and as a guest in VirtualBox (Win10 host, 8 cores, 16 GB memory).


# How to run in Docker

If you have docker installed you can run the test with it:

    $ docker run --rm -it --name xbuild-loop nuumio/xbuild-loop

To see how the loop is going you can `tail` its log:

    $ docker exec xbuild-loop tail -f /linux-build/logs/build-loop.txt

To stop the loop keep hitting ctrl-c or run:

    $ docker container stop xbuild-loop


# How to run without Docker

If you don't have Docker installed and don't want to install it you can install needed tools and run the build loop script:

    # Install few tools
    $ sudo apt install bc bison build-essential \
        crossbuild-essential-arm64 curl flex git \
        libssl-dev python unzip

    # Create and cd to suitable working dir
    $ mkdir -p /tmp/build-test && cd /tmp/build-test

    # Get the source and run
    $ git clone https://github.com/nuumio/xbuild-loop.git
    $ xbuild-loop/build-loop.sh

To see how the loop is going you can `tail` its log:

    $ cd /tmp/build-test && tail -f build-logs/build-loop.txt

To stop the loop keep hitting ctrl-c.


# How to run in terminal without the script

Install tools as above and then:

    # Get the source
    $ curl -LO https://github.com/nuumio/linux-kernel/archive/nuumio-4.4-pcie-scan-sleep-01.zip
    $ unzip nuumio-4.4-pcie-scan-sleep-01.zip

    # Run until failure or ctrl-c
    $ cd linux-kernel-nuumio-4.4-pcie-scan-sleep-01
    $ while true; \
        do make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
        mrproper rockchip_linux_defconfig all \
        -j$(($(nproc)*3/2)) || break; done

To stop the loop keep hitting ctrl-c.


# Things to watch while the loop is running

You may want to `tail` syslog in one terminal to see if there's anything strange going on:

    $ tail -f /var/log/syslog

And in another terminal run `top` to see system load, IO wait and stuff:

    $ top


# What goes wrong when running natively

When running the test natively in Ubuntu 18.04 builds seem to success but the system itself becomes "sluggish" and finally halts totally. The first sign seems to be extremely high IO wait (wa) in `top`:

    top - 17:12:39 up 18 min,  1 user,  load average: 24,33, 20,60, 11,72
    Tasks: 445 total,   1 running, 341 sleeping,   0 stopped,   0 zombie
    %Cpu(s):  2,0 us,  0,3 sy,  0,0 ni, 13,6 id, 84,1 wa,  0,0 hi,  0,0 si,  0,0 st
    KiB Mem : 32931556 total, 26069564 free,  1256644 used,  5605348 buff/cache
    KiB Swap:  2097148 total,  2097148 free,        0 used. 31173936 avail Mem

      PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
        8 root      20   0       0      0      0 I   0,3  0,0   0:00.80 rcu_sched
       58 root      20   0       0      0      0 S   0,3  0,0   0:00.53 ksoftirqd/8
      493 root      20   0       0      0      0 I   0,3  0,0   0:00.58 kworker/2:2
     1816 root      20   0  531356  85296  67420 S   0,3  0,3   0:42.45 Xorg
     1900 root     -51   0       0      0      0 S   0,3  0,0   0:20.70 irq/97-nvidia
     3953 nuumio    20   0  809984  39748  27388 S   0,3  0,1   0:17.36 gnome-terminal-
     7199 root      20   0   23324   7460   4056 S   0,3  0,0   0:00.01 python
    28867 nuumio    20   0   54892   4740   3672 R   0,3  0,0   0:02.06 top

High IO wait can happen at any time and it lasts for few seconds. After that everything goes fine for some time until it happens again. When running the loop long enough (usually 15-30 minutes is enough) HARD or SOFT CPU lockups happen and system gets totally stuck. Forced reset is the only way to recover. Lockups look like this in `syslog` or `dmesg`:

    [ 1931.793611] INFO: rcu_sched detected stalls on CPUs/tasks:
    [ 1931.793621]  2-...0: (1 GPs behind) idle=ee6/140000000000000/0 softirq=643232/643237 fqs=7226
    [ 1931.793626]  3-...0: (1 GPs behind) idle=e9a/140000000000000/0 softirq=627791/627801 fqs=7226
    [ 1931.793627]  (detected by 1, t=15002 jiffies, g=57598, c=57597, q=1712307)
    [ 1931.793632] Sending NMI from CPU 1 to CPUs 2:
    [ 1941.716655] Sending NMI from CPU 1 to CPUs 3:
    [ 2080.044212] watchdog: BUG: soft lockup - CPU#5 stuck for 23s! [kworker/5:1:173]
    [ 2080.044216] Modules linked in: ipt_MASQUERADE nf_nat_masquerade_ipv4 nf_conntrack_netlink nfnetlink xfrm_user xfrm_algo iptable_nat nf_conntrack_ipv4 nf_defrag_ipv4 nf_nat_ipv4 xt_addrtype iptable_filter xt_conntrack nf_nat nf_conntrack libcrc32c br_netfilter bridge stp llc aufs overlay binfmt_misc nls_iso8859_1 snd_hda_codec_hdmi nvidia_uvm(POE) nvidia_drm(POE) nvidia_modeset(POE) nvidia(POE) drm_kms_helper snd_hda_codec_realtek drm snd_hda_codec_generic ipmi_devintf snd_hda_intel ipmi_msghandler eeepc_wmi snd_hda_codec snd_hda_core asus_wmi fb_sys_fops sparse_keymap syscopyarea video snd_hwdep snd_pcm snd_seq_midi snd_seq_midi_event snd_rawmidi snd_seq snd_seq_device wmi_bmof mxm_wmi snd_timer joydev ch341 sysfillrect usbserial input_leds snd sysimgblt ccp soundcore k10temp edac_mce_amd shpchp
    [ 2080.044252]  kvm_amd kvm irqbypass crct10dif_pclmul crc32_pclmul ghash_clmulni_intel mac_hid pcbc wmi aesni_intel aes_x86_64 crypto_simd glue_helper cryptd sch_fq_codel parport_pc ppdev lp parport ip_tables x_tables autofs4 hid_logitech_hidpp hid_logitech_dj usbhid hid igb i2c_algo_bit i2c_piix4 dca ptp ahci pps_core libahci gpio_amdpt gpio_generic
    [ 2080.044271] CPU: 5 PID: 173 Comm: kworker/5:1 Tainted: P           OE    4.15.0-46-generic #49-Ubuntu
    [ 2080.044272] Hardware name: System manufacturer System Product Name/CROSSHAIR VI HERO, BIOS 6401 12/07/2018
    [ 2080.044277] Workqueue: events netstamp_clear
    [ 2080.044282] RIP: 0010:smp_call_function_many+0x229/0x250
    [ 2080.044283] RSP: 0018:ffffa601c3b07d00 EFLAGS: 00000202 ORIG_RAX: ffffffffffffff11
    [ 2080.044284] RAX: 0000000000000002 RBX: ffff9acb3e7638c0 RCX: 0000000000000001
    [ 2080.044285] RDX: ffff9acb3e6a88c0 RSI: 0000000000000000 RDI: ffff9acb3e026270
    [ 2080.044286] RBP: ffffa601c3b07d38 R08: fffffffffffffffc R09: 000000000000ffdf
    [ 2080.044287] R10: fffffa335fc6a040 R11: 0000000000000e80 R12: 0000000000000010
    [ 2080.044288] R13: 0000000000023880 R14: ffffffff900353c0 R15: 0000000000000000
    [ 2080.044289] FS:  0000000000000000(0000) GS:ffff9acb3e740000(0000) knlGS:0000000000000000
    [ 2080.044291] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
    [ 2080.044291] CR2: 00007f06ff6a1300 CR3: 00000007f52b2000 CR4: 00000000003406e0
    [ 2080.044292] Call Trace:
    [ 2080.044297]  ? netif_receive_skb_internal+0x20/0xe0
    [ 2080.044299]  ? cpumask_weight+0x20/0x20
    [ 2080.044301]  ? netif_receive_skb_internal+0x21/0xe0
    [ 2080.044303]  on_each_cpu+0x2d/0x60
    [ 2080.044304]  ? netif_receive_skb_internal+0x20/0xe0
    [ 2080.044306]  text_poke_bp+0x6a/0xf0
    [ 2080.044308]  __jump_label_transform.isra.0+0x10e/0x120
    [ 2080.044310]  arch_jump_label_transform+0x32/0x50
    [ 2080.044313]  __jump_label_update+0x68/0x80
    [ 2080.044314]  jump_label_update+0xae/0xc0
    [ 2080.044316]  static_key_enable_cpuslocked+0x55/0x80
    [ 2080.044318]  static_key_enable+0x1a/0x30
    [ 2080.044319]  netstamp_clear+0x2d/0x40
    [ 2080.044322]  process_one_work+0x1de/0x410
    [ 2080.044323]  worker_thread+0x32/0x410
    [ 2080.044326]  kthread+0x121/0x140
    [ 2080.044327]  ? process_one_work+0x410/0x410
    [ 2080.044329]  ? kthread_create_worker_on_cpu+0x70/0x70
    [ 2080.044332]  ret_from_fork+0x22/0x40
    [ 2080.044333] Code: 89 c7 e8 5b a8 85 00 3b 05 d9 d7 53 01 0f 83 5c fe ff ff 48 63 c8 48 8b 13 48 03 14 cd c0 a6 1a 91 8b 4a 18 83 e1 01 74 0a f3 90 <8b> 4a 18 83 e1 01 75 f6 eb c7 48 c7 c2 a0 de 65 91 4c 89 e6 89

or:

    [ 1389.864471] INFO: rcu_sched detected stalls on CPUs/tasks:
    [ 1389.864480] 	2-...0: (1 GPs behind) idle=f96/140000000000000/0 softirq=376702/376747 fqs=7326
    [ 1389.864483] 	3-...0: (1 GPs behind) idle=cc6/140000000000000/0 softirq=375353/375354 fqs=7326
    [ 1389.864484] 	(detected by 1, t=15002 jiffies, g=41759, c=41758, q=3782424)
    [ 1389.864488] Sending NMI from CPU 1 to CPUs 2:
    [ 1398.536651] NMI watchdog: Watchdog detected hard LOCKUP on cpu 4
    [ 1398.536652] Modules linked in: veth ipt_MASQUERADE nf_nat_masquerade_ipv4 nf_conntrack_netlink nfnetlink xfrm_user xfrm_algo iptable_nat nf_conntrack_ipv4 nf_defrag_ipv4 nf_nat_ipv4 xt_addrtype iptable_filter xt_conntrack nf_nat nf_conntrack libcrc32c br_netfilter bridge stp llc aufs overlay binfmt_misc nls_iso8859_1 snd_hda_codec_hdmi nvidia_uvm(POE) nvidia_drm(POE) nvidia_modeset(POE) nvidia(POE) snd_hda_codec_realtek snd_hda_codec_generic snd_hda_intel snd_hda_codec snd_hda_core snd_hwdep snd_pcm snd_seq_midi snd_seq_midi_event snd_rawmidi edac_mce_amd drm_kms_helper ch341 kvm_amd snd_seq drm usbserial eeepc_wmi kvm asus_wmi joydev ipmi_devintf snd_seq_device snd_timer input_leds ipmi_msghandler sparse_keymap fb_sys_fops video syscopyarea wmi_bmof mxm_wmi snd sysfillrect irqbypass sysimgblt soundcore
    [ 1398.536678]  crct10dif_pclmul crc32_pclmul ghash_clmulni_intel ccp pcbc shpchp aesni_intel k10temp aes_x86_64 crypto_simd glue_helper cryptd mac_hid wmi sch_fq_codel parport_pc ppdev lp parport ip_tables x_tables autofs4 uas usb_storage hid_logitech_hidpp hid_logitech_dj usbhid hid igb i2c_algo_bit dca i2c_piix4 ptp ahci pps_core libahci gpio_amdpt gpio_generic
    [ 1398.536692] CPU: 4 PID: 8 Comm: rcu_sched Tainted: P           OE    4.15.0-46-generic #49-Ubuntu
    [ 1398.536693] Hardware name: System manufacturer System Product Name/CROSSHAIR VI HERO, BIOS 6401 12/07/2018
    [ 1398.536698] RIP: 0010:native_queued_spin_lock_slowpath+0x135/0x1a0
    [ 1398.536699] RSP: 0018:ffffa145c321be30 EFLAGS: 00000002
    [ 1398.536700] RAX: 0000000000180101 RBX: 0000000000000246 RCX: 0000000000000001
    [ 1398.536700] RDX: 0000000000000101 RSI: 0000000000000001 RDI: ffffffffbd8a9240
    [ 1398.536701] RBP: ffffa145c321be30 R08: 0000000000000101 R09: ffff8a47b09f1618
    [ 1398.536701] R10: 0000000000000000 R11: 0000000000000040 R12: 0000000000000000
    [ 1398.536702] R13: ffffffffbd8a9240 R14: 0000000000000000 R15: ffffffffbd8a9240
    [ 1398.536703] FS:  0000000000000000(0000) GS:ffff8a485ed00000(0000) knlGS:0000000000000000
    [ 1398.536704] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
    [ 1398.536704] CR2: 00007f6f9f6c5002 CR3: 00000004f88e8000 CR4: 00000000003406e0
    [ 1398.536705] Call Trace:
    [ 1398.536710]  _raw_spin_lock_irqsave+0x37/0x40
    [ 1398.536711]  force_qs_rnp+0xd9/0x1b0
    [ 1398.536712]  ? sync_rcu_exp_select_cpus+0x420/0x420
    [ 1398.536713]  rcu_gp_kthread+0x54e/0x960
    [ 1398.536716]  kthread+0x121/0x140
    [ 1398.536717]  ? rcu_note_context_switch+0x150/0x150
    [ 1398.536718]  ? kthread_create_worker_on_cpu+0x70/0x70
    [ 1398.536719]  ret_from_fork+0x22/0x40
    [ 1398.536720] Code: 66 31 c0 41 39 c0 74 ea 4d 85 c9 c6 07 01 74 2d 41 c7 41 08 01 00 00 00 eb 96 83 fa 01 0f 84 f4 fe ff ff 8b 07 84 c0 74 08 f3 90 <8b> 07 84 c0 75 f8 b8 01 00 00 00 66 89 07 5d c3 f3 90 4c 8b 09


# What goes wrong when running in VM

In my system, when running in a VirtualBox VM (Win10 host, 8 cores, 16 GB memory), builds start to fail randomly. Usually they fail either with `UnicodeEncodeError` from `gcc-wrapper.py` or with `Segmentation fault` and first fails usually happen in less than 45 minutes. Sometimes it may take really long time and sometimes it may happen on the first round. If you inspect build logs from each round (`build-log-NNN.txt`) you may see something like this:

    Traceback (most recent call last):
        File "./scripts/gcc-wrapper.py", line 115, in <module>
            status = run_gcc()
        File "./scripts/gcc-wrapper.py", line 98, in run_gcc
            print (line.decode("utf-8"), end="")
    UnicodeEncodeError: 'ascii' codec can't encode character u'\u2018' in position 41: ordinal not in range(128)
    scripts/Makefile.build:277: recipe for target 'drivers/usb/host/ohci-hcd.o' failed
    make[4]: *** [drivers/usb/host/ohci-hcd.o] Error 1

or this:

    aarch64-linux-gnu-gcc: internal compiler error: Segmentation fault (program cc1)
    Please submit a full bug report,
    with preprocessed source if appropriate.
    See <file:///usr/share/doc/gcc-7/README.Bugs> for instructions.
    scripts/Makefile.modpost:114: recipe for target 'drivers/media/dvb-frontends/lgdt3305.mod.o' failed
    make[2]: *** [drivers/media/dvb-frontends/lgdt3305.mod.o] Error 4

GCC seems to catch the most of segfault but some may get to `dmesg` or `syslog` and they look like this:

    [ 4634.478252] traps: cc1[27440] general protection ip:554014 sp:7ffc728dadb0 error:0 in cc1[400000+faf000]
    [11407.364112] cc1[27022]: segfault at 0 ip 0000000000000000 sp 00007ffd802b4008 error 14 in cc1[400000+faf000]

Every now and then the host Windows 10 crashes too with `Stop code: CLOCK_WATCHDOG_TIMEOUT`


# My system

Hardware:

  * AMD Ryzen 7 2700X
  * Asus CROSSHAIR VI HERO, BIOS 6401
  * G.Skill Ripjaws V F4-3200C14-16GVK 2 x 16 GB
  * Asus GTX 1060 DUAL 6GB
  * 850 EVO 1 TB, 850 EVO 500 GB, 840 EVO 500 GB, MX100 512 GB, WD Green M2 SATA 240 GB
  * Noctua NH-D15-SE-AM4
  * Corsair RM750x

OSes and software:

  * Ubuntu 18.04, kernel 4.15.0-46-generic (both native and VM guest)
  * Win 10 Pro, Version 1803 (OS Build 17134.590) (VM host)
  * VirtualBox, VirtualBox: Version 5.2.26 r128414 (Qt5.6.2)

Setup: C6H BIOS has been first set to defaults and then memory speed has been set to 2933 MHz. Win 10 installed to 500 GB 850 EVO, Linux VM image in 1TB 850 EVO, native Linux in WD Green.


# Other notes

I selected the specific version of Linux (4.4) kernel and arm64 cross-compile because it was giving me the most trouble. Building mainline kernel for x86_64 fails too - just not as easily. This is at least how it feels.
