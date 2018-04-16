
section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, 3
mov [esp - 4], eax
mov eax, 4
add [esp - 4], eax
mov eax, [esp - 4]
mov [esp - 4], eax
mov eax, 2
add [esp - 4], eax
mov eax, [esp - 4]
  ret

