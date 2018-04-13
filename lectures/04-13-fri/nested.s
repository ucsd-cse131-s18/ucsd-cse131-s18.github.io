
section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, 10
mov [esp - 4], eax
mov eax, [esp - 4]
add eax, 1
mov [esp - 4], eax
mov eax, [esp - 4]
add eax, 1
mov [esp - 8], eax
mov eax, [esp - 8]
  ret

