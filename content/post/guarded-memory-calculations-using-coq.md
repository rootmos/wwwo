---
title: "Guarded memory calculations using Coq"
additional_css: [ "coqdoc.css" ]
---

The aim of this text is to entice you to consider Coq (or other proof assistants) when dealing with integer arithmetics.
The text is not aimed to provide a proof of a sophisticated problem, but it is a proof of something a developer almost certainly would encounter in the real world.

Guard pages are intended to help catch unintentional or malicious buffer overflows.

This is accomplished by [mmap](https://man.archlinux.org/man/mmap.2)
and [mprotect](https://man.archlinux.org/man/mprotect.2).

This memory allocation scheme might seem exceedingly wasteful.
But I think (meaning I trust but haven't verified) the guard pages will not take up any physical memory, only virtual memory, since the kernel should treat them as copy-on-write and by design we will not write to them.

The resulting code I came up with revolved the following definition,
which represents the number of alignments (A) needed to compute the offset
such that the allocation's data region is as close to the upper guard page.
<p class="code">
<span class="id" title="keyword">Definition</span> <span class="id" title="var">pad_minimizer</span> <span class="id" title="var">A</span> <span class="id" title="var">n</span> <span class="id" title="var">P</span> :=<br/>
&nbsp;&nbsp;<span class="id" title="keyword">if</span> <span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span> =? 0 <span class="id" title="keyword">then</span> 0 <span class="id" title="keyword">else</span><br/>
&nbsp;&nbsp;<span class="id" title="keyword">if</span> (<span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span>) <span class="id" title="var">mod</span> <span class="id" title="var">A</span> =? 0<br/>
&nbsp;&nbsp;<span class="id" title="keyword">then</span> <span class="id" title="var">P</span> / <span class="id" title="var">A</span> - (<span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span>) / <span class="id" title="var">A</span><br/>
&nbsp;&nbsp;<span class="id" title="keyword">else</span> <span class="id" title="var">P</span> / <span class="id" title="var">A</span> - 1 - (<span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span>) / <span class="id" title="var">A</span>.<br/>
</p>
Imagine you stumble upon this experession, how sure are you of its correctness?

# Sketch

## The problem
Wanted to implement guarded memory allocations (a la [libsodium](https://doc.libsodium.org/memory_management#guarded-heap-allocations)) in rust.

Two inaccessible memory pages (any access yields a page-fault) surrounding an accessible range snugged up against the upper guardpage.

![guarded memory allocations](guarded-memory-sketch.jpg)

Rust's memory allocators receive a desired [memory layout](https://doc.rust-lang.org/std/alloc/struct.Layout.html#method.from_size_align)
which specifies not only the size but also the alignment.
And the only guarantee we get regarding the alignment is that its a power of 2.

## The code
<p class="code">
<span class="id" title="keyword">Definition</span> <span class="id" title="var">pad</span> <span class="id" title="var">x</span> <span class="id" title="var">N</span> :=<br/>
&nbsp;&nbsp;<span class="id" title="keyword">match</span> <span class="id" title="var">x</span> <span class="id" title="var">mod</span> <span class="id" title="var">N</span> <span class="id" title="keyword">with</span> 0 =&gt; 0 | <span class="id" title="var">r</span> =&gt; <span class="id" title="var">N</span> - <span class="id" title="var">r</span> <span class="id" title="keyword">end</span>.<br/>

<br/>
<span class="id" title="keyword">Definition</span> <span class="id" title="var">aligned</span> <span class="id" title="var">x</span> <span class="id" title="var">N</span> := <span class="id" title="var">N</span> &lt;&gt; 0 /\ <span class="id" title="var">pad</span> <span class="id" title="var">x</span> <span class="id" title="var">N</span> = 0.<br/>

<br/>
<span class="id" title="keyword">Proposition</span> <span class="id" title="var">aligned_alt_def</span> {<span class="id" title="var">x</span> <span class="id" title="var">N</span>}: <span class="id" title="var">aligned</span> <span class="id" title="var">x</span> <span class="id" title="var">N</span> &lt;-&gt; <span class="id" title="var">N</span> &lt;&gt; 0 /\ <span class="id" title="var">x</span> <span class="id" title="var">mod</span> <span class="id" title="var">N</span> = 0.<br/>

<br/>
<span class="id" title="keyword">Definition</span> <span class="id" title="var">pad_minimizer</span> <span class="id" title="var">A</span> <span class="id" title="var">n</span> <span class="id" title="var">P</span> :=<br/>
&nbsp;&nbsp;<span class="id" title="keyword">if</span> <span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span> =? 0 <span class="id" title="keyword">then</span> 0 <span class="id" title="keyword">else</span><br/>
&nbsp;&nbsp;<span class="id" title="keyword">if</span> (<span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span>) <span class="id" title="var">mod</span> <span class="id" title="var">A</span> =? 0<br/>
&nbsp;&nbsp;<span class="id" title="keyword">then</span> <span class="id" title="var">P</span> / <span class="id" title="var">A</span> - (<span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span>) / <span class="id" title="var">A</span><br/>
&nbsp;&nbsp;<span class="id" title="keyword">else</span> <span class="id" title="var">P</span> / <span class="id" title="var">A</span> - 1 - (<span class="id" title="var">n</span> <span class="id" title="var">mod</span> <span class="id" title="var">P</span>) / <span class="id" title="var">A</span>.<br/>

<br/>
<span class="id" title="keyword">Proposition</span> <span class="id" title="var">pad_min</span> <span class="id" title="var">A</span> <span class="id" title="var">n</span> <span class="id" title="var">P</span>: <span class="id" title="var">aligned</span> <span class="id" title="var">P</span> <span class="id" title="var">A</span> -&gt;<br/>
&nbsp;&nbsp;<span class="id" title="keyword">let</span> <span class="id" title="var">i</span> := <span class="id" title="var">pad_minimizer</span> <span class="id" title="var">A</span> <span class="id" title="var">n</span> <span class="id" title="var">P</span> <span class="id" title="tactic">in</span><br/>
&nbsp;&nbsp;<span class="id" title="keyword">forall</span> <span class="id" title="var">j</span>, <span class="id" title="var">pad</span> (<span class="id" title="var">A</span> * <span class="id" title="var">i</span> + <span class="id" title="var">n</span>) <span class="id" title="var">P</span> &lt;= <span class="id" title="var">pad</span> (<span class="id" title="var">A</span> * <span class="id" title="var">j</span> + <span class="id" title="var">n</span>) <span class="id" title="var">P</span>.<br/>

<br/>
<span class="id" title="keyword">Axiom</span> <span class="id" title="var">accessible</span> : <span class="id" title="var">nat</span> -&gt; <span class="id" title="keyword">Prop</span>.<br/>
<span class="id" title="keyword">Definition</span> <span class="id" title="var">accessible_range</span> <span class="id" title="var">b</span> <span class="id" title="var">n</span> := <span class="id" title="keyword">forall</span> <span class="id" title="var">m</span>, <span class="id" title="var">m</span> &lt; <span class="id" title="var">n</span> -&gt; <span class="id" title="var">accessible</span> (<span class="id" title="var">b</span> + <span class="id" title="var">m</span>).<br/>
<span class="id" title="keyword">Definition</span> <span class="id" title="var">mmap</span> <span class="id" title="var">P</span> := <span class="id" title="keyword">forall</span> <span class="id" title="var">n</span>, { <span class="id" title="var">p</span> | <span class="id" title="var">aligned</span> <span class="id" title="var">p</span> <span class="id" title="var">P</span> /\ <span class="id" title="var">accessible_range</span> <span class="id" title="var">p</span> <span class="id" title="var">n</span> }.<br/>

<br/>
<span class="id" title="keyword">Record</span> <span class="id" title="var">Allocation</span> (<span class="id" title="var">n</span> <span class="id" title="var">A</span>: <span class="id" title="var">nat</span>) := <span class="id" title="var">mkAllocation</span> {<br/>
&nbsp;&nbsp;<span class="id" title="var">data</span>: <span class="id" title="var">nat</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">data_alignment</span>: <span class="id" title="var">aligned</span> <span class="id" title="var">data</span> <span class="id" title="var">A</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">data_accessible</span>: <span class="id" title="var">accessible_range</span> <span class="id" title="var">data</span> <span class="id" title="var">n</span>;<br/>
}.<br/>

<br/>
<span class="id" title="keyword">Record</span> <span class="id" title="var">GuardedAllocation</span> (<span class="id" title="var">n</span> <span class="id" title="var">A</span> <span class="id" title="var">P</span>: <span class="id" title="var">nat</span>) := <span class="id" title="var">mkGuardedAllocation</span> {<br/>
&nbsp;&nbsp;<span class="id" title="var">allocation</span>: <span class="id" title="var">Allocation</span> <span class="id" title="var">n</span> <span class="id" title="var">A</span>;<br/>
<br/>
&nbsp;&nbsp;<span class="id" title="var">mmapper</span>: <span class="id" title="var">mmap</span> <span class="id" title="var">P</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">mmapped_size</span>: <span class="id" title="var">nat</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">base</span> := <span class="id" title="var">proj1_sig</span> (<span class="id" title="var">mmapper</span> <span class="id" title="var">mmapped_size</span>);<br/>
<br/>
&nbsp;&nbsp;<span class="id" title="var">data'</span> := <span class="id" title="var">data</span> <span class="id" title="var">_</span> <span class="id" title="var">_</span> <span class="id" title="var">allocation</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">offset</span>: <span class="id" title="var">nat</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">pad_pre</span>: <span class="id" title="var">nat</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">data_offset</span>: <span class="id" title="var">data'</span> = <span class="id" title="var">base</span> + (1 + <span class="id" title="var">offset</span>) * <span class="id" title="var">P</span> + <span class="id" title="var">pad_pre</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">post_guard</span>: (1 + <span class="id" title="var">offset</span>) * <span class="id" title="var">P</span> + <span class="id" title="var">pad_pre</span> + <span class="id" title="var">n</span> + <span class="id" title="var">pad</span> (<span class="id" title="var">data'</span> + <span class="id" title="var">n</span>) <span class="id" title="var">P</span> + <span class="id" title="var">P</span> &lt;= <span class="id" title="var">mmapped_size</span>;<br/>
}.<br/>

<br/>
<span class="id" title="keyword">Record</span> <span class="id" title="var">OptimalAllocation</span> (<span class="id" title="var">n</span> <span class="id" title="var">A</span> <span class="id" title="var">P</span>: <span class="id" title="var">nat</span>) := <span class="id" title="var">mkOptimalAllocation</span> {<br/>
&nbsp;&nbsp;<span class="id" title="var">guarded_allocation</span>: <span class="id" title="var">GuardedAllocation</span> <span class="id" title="var">n</span> <span class="id" title="var">A</span> <span class="id" title="var">P</span>;<br/>
&nbsp;&nbsp;<span class="id" title="var">post_padding_min</span>: <span class="id" title="keyword">forall</span> <span class="id" title="var">a'</span>: <span class="id" title="var">GuardedAllocation</span> <span class="id" title="var">n</span> <span class="id" title="var">A</span> <span class="id" title="var">P</span>,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;<span class="id" title="var">pad</span> (<span class="id" title="var">data'</span> <span class="id" title="var">_</span> <span class="id" title="var">_</span> <span class="id" title="var">_</span> <span class="id" title="var">guarded_allocation</span> + <span class="id" title="var">n</span>) <span class="id" title="var">P</span> &lt;= <span class="id" title="var">pad</span> (<span class="id" title="var">data'</span> <span class="id" title="var">_</span> <span class="id" title="var">_</span> <span class="id" title="var">_</span> <span class="id" title="var">a'</span> + <span class="id" title="var">n</span>) <span class="id" title="var">P</span>;<br/>
}.<br/>

<br/>
<span class="id" title="keyword">Proposition</span> <span class="id" title="var">optimal_allocator_page_aligned</span> {<span class="id" title="var">P</span>} (<span class="id" title="var">M</span>: <span class="id" title="var">mmap</span> <span class="id" title="var">P</span>):<br/>
&nbsp;&nbsp;<span class="id" title="keyword">forall</span> <span class="id" title="var">n</span> {<span class="id" title="var">A</span>}, <span class="id" title="var">aligned</span> <span class="id" title="var">P</span> <span class="id" title="var">A</span> -&gt; <span class="id" title="var">OptimalAllocation</span> <span class="id" title="var">n</span> <span class="id" title="var">A</span> <span class="id" title="var">P</span>.<br/>

<br/>
<span class="id" title="keyword">Proposition</span> <span class="id" title="var">optimal_allocator_super_page_aligned</span> {<span class="id" title="var">P</span>} (<span class="id" title="var">M</span>: <span class="id" title="var">mmap</span> <span class="id" title="var">P</span>):<br/>
&nbsp;&nbsp;<span class="id" title="keyword">forall</span> <span class="id" title="var">n</span> {<span class="id" title="var">A</span>}, <span class="id" title="var">A</span> &lt;&gt; 0 -&gt; <span class="id" title="var">aligned</span> <span class="id" title="var">A</span> <span class="id" title="var">P</span> -&gt; <span class="id" title="var">OptimalAllocation</span> <span class="id" title="var">n</span> <span class="id" title="var">A</span> <span class="id" title="var">P</span>.<br/>

<br/>
<span class="id" title="keyword">Lemma</span> <span class="id" title="var">power_of_two</span>: <span class="id" title="keyword">forall</span> <span class="id" title="var">a</span> <span class="id" title="var">b</span>, {<span class="id" title="var">aligned</span> (2^<span class="id" title="var">a</span>) (2^<span class="id" title="var">b</span>)} + {<span class="id" title="var">aligned</span> (2^<span class="id" title="var">b</span>) (2^<span class="id" title="var">a</span>)}.<br/>

<br/>
<span class="id" title="keyword">Theorem</span> <span class="id" title="var">optimal_allocator</span> (<span class="id" title="var">M</span>: <span class="id" title="var">mmap</span> 4096):<br/>
&nbsp;&nbsp;<span class="id" title="keyword">forall</span> <span class="id" title="var">n</span> <span class="id" title="var">a</span>, <span class="id" title="var">OptimalAllocation</span> <span class="id" title="var">n</span> (2^<span class="id" title="var">a</span>) 4096.<br/>
</p>
