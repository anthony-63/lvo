/* Stuff needed in libgcc for stack probes.
 *
 *   Copyright (C) 1996, 1998, 2001, 2003, 2008 Free Software Foundation, Inc.
 *   Written By Steve Chamberlain
 * 
 * This file is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2, or (at your option) any
 * later version.
 * 
 * In addition to the permissions in the GNU General Public License, the
 * Free Software Foundation gives you unlimited permission to link the
 * compiled version of this file with other programs, and to distribute
 * those programs without any restriction coming from the use of this
 * file.  (The General Public License restrictions do apply in other
 * respects; for example, they cover modification of the file, and
 * distribution when not linked into another program.)
 * 
 * This file is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 * 
 *    As a special exception, if you link this library with files
 *    compiled with GCC to produce an executable, this does not cause
 *    the resulting executable to be covered by the GNU General Public License.
 *    This exception does not however invalidate any other reasons why
 *    the executable file might be covered by the GNU General Public License.
 */
#ifdef L_chkstk
/* Function prologue calls _alloca to probe the stack when allocating more
   than CHECK_STACK_LIMIT bytes in one go.  Touching the stack at 4K
   increments is necessary to ensure that the guard pages used
   by the OS virtual memory manger are allocated in correct sequence.  */
	.global ___chkstk
	.global	__alloca
#ifndef __x86_64__
___chkstk:
__alloca:
	pushl	%ecx		/* save temp */
	movl	%esp, %ecx
	cmpl	$0x1000, %eax	/* > 4k ?*/
	jb	Ldone
	/* 0x1000 - 0x8 = 0xff8.
	   8 bytes to point past return address and ecx saved on the stack.  */
	subl	$0xff8, %esp
	jmp	Lprobe1
Lprobe:
	subl	$0x1000, %esp  		/* yes, move pointer down 4k*/
Lprobe1:
	orl	$0x0, (%esp)   		/* probe there */
	subl	$0x1000, %eax  	 	/* decrement count */
	cmpl	$0x1000, %eax
	ja	Lprobe         	 	/* and do it again */
	jmp	Ldone1
Ldone:
	/* 8 bytes to point past return address and ecx saved on the stack.  */
	subl	$0x8, %eax
Ldone1:	
	subl	%eax, %esp
	orl	$0x0, (%esp)	/* less than 4k, just peek here */
	movl	%ecx, %eax	/* save old stack pointer */
	movl	(%eax), %ecx	/* recover saved temp */
	movl	4(%eax), %eax	/* recover return address */
	/* Push the return value back.  Doing this instead of just
	   jumping to %eax preserves the cached call-return stack
	   used by most modern processors.  */
	pushl	%eax
	ret
#else
/* __alloca is a normal function call, which uses %rcx as the argument.  And stack space
   for the argument is saved.  */
__alloca:
 	movq	%rcx, %rax
	addq	$0x7, %rax
	andq	$0xfffffffffffffff8, %rax
	popq	%rcx		/* pop return address */
	popq	%r10		/* Pop the reserved stack space.  */
	movq	%rsp, %r10	/* get sp */
	cmpq	$0x1000, %rax	/* > 4k ?*/
	jb	Ldone_alloca
Lprobe_alloca:
	subq	$0x1000, %r10  		/* yes, move pointer down 4k*/
	movq	%r10, %rsp		/* update sp before probing */
	orq	$0x0, (%r10)   		/* probe there */
	subq	$0x1000, %rax  	 	/* decrement count */
	cmpq	$0x1000, %rax
	ja	Lprobe_alloca         	 	/* and do it again */
Ldone_alloca:
	subq	%rax, %r10
	movq	%r10, %rsp	/* update sp before probing */
	orq	$0x0, (%r10)	/* less than 4k, just peek here */
	movq	%r10, %rax
	subq	$0x8, %r10	/* Reserve argument stack space.  */
	movq	%r10, %rsp	/* decrement stack */
	/* Push the return value back.  Doing this instead of just
	   jumping to %rcx preserves the cached call-return stack
	   used by most modern processors.  */
	pushq	%rcx
	ret
/* ___chkstk is a *special* function call, which uses %rax as the argument.
   We avoid clobbering the 4 integer argument registers, %rcx, %rdx, 
   %r8 and %r9, which leaves us with %rax, %r10, and %r11 to use.  */
___chkstk:
	addq	$0x7, %rax	/* Make sure stack is on alignment of 8.  */
	andq	$0xfffffffffffffff8, %rax
	popq	%r11		/* pop return address */
	movq	%rsp, %r10	/* get sp */
	cmpq	$0x1000, %rax	/* > 4k ?*/
	jb	Ldone
Lprobe:
	subq	$0x1000, %r10  		/* yes, move pointer down 4k*/
	movq	%r10, %rsp		/* update sp before probing */
	orl	$0x0, (%r10)   		/* probe there */
	subq	$0x1000, %rax  	 	/* decrement count */
	cmpq	$0x1000, %rax
	ja	Lprobe         	 	/* and do it again */
Ldone:
	subq	%rax, %r10
	movq	%r10, %rsp	/* update sp before probing */
	orl	$0x0, (%r10)	/* less than 4k, just peek here */
	/* Push the return value back.  Doing this instead of just
	   jumping to %r11 preserves the cached call-return stack
	   used by most modern processors.  */
	pushq	%r11
	ret
#endif
#endif
#ifdef __linux__
	/* We do not need executable stack.  */
	.section	.note.GNU-stack,"",@progbits
#endif