; Author: Odey John Ebinyi aka Hotwrist 
; Assembly language demonstration program

; Build either with the automatic build script:
; "build_asm_vX.sh coursework_1_demo.asm"
; OR
; Assemble command:
; "nasm -g -f elf64 -o coursework_1_demo.o coursework_1_demo.asm"
; Link command:
; "gcc coursework_1_demo.o -no-pie -o coursework_1_demo"
; Executable generated is: "coursework_1_demo"
; Can be run with: "./coursework_1_demo"

; This include line is an absolute path to the I/O library. You may wish to change it to suit your own file system.
;%include "/home/malware/asm/joey_lib_io_v6_release.asm"
%include "joey_lib_io_v6_release.asm"

; "global main" defines the entry point of the executable upon linking.
; In other words, "main" defines the point in the code from which the final executable starts execution.
global main

; The ".data" section is where initialised data in memory is defined. This is where we define strings and other predefined data.
; This section is read/write but NOT executable. If it were executable, someone could modify the data to be malicious executable code and then execute it.
; We don't want that! See "Data Execution Prevention (DEP)".
; "db" means "Define Byte", which allocates 1 byte.
; We could also use:
; "dw" = "Define Word", which allocates 2 bytes
; "dd" = "Define Doubleword", which allocates 4 bytes
; "dq" = "Define Quadword, which allocates 8 bytes
section .data 
    str_main_menu db 10,\
                            "Main Menu", 10,\
                            " 1. Add User / Add Computer", 10,\
			    " 2. Delete a User / Delete a Computer", 10, \
			    " 3. Search a User / Search a Computer", 10, \
                            " 4. List All Users / List All Computers", 10, \
                            " 5. Count Users / Count Computers", 10,\
                            " 6. Exit", 10,\
                            "Please Enter Option 1 - 6", 10, 0
              
    ; Because we are working on the details pertaining to computers and users, the below declaration is used
    ; so that the admin can be specific about the user or computer to add, delete, search or list, based on his
    ; choice in the 'str_main_menu' above.              
    str_make_choice db "[1]. Computer", 10, \
    		       "[2]. User", 10, \
    		       "[3]. Exit", 10, \
    		       "Please Enter Option 1 - 3", 10, 0
 
    ; Note - after each string we add bytes of value 10 and zero (decimal). 
    ; These are ASCII codes for linefeed and NULL, respectively.
    ; The NULL is required because we are using null-terminated strings. 
    ; The linefeed makes the console drop down a line, which saves us having to call "print_nl_new" function separately.
    ; In fact, some strings defined here do not have a linefeed character. 
    ; These are for occations when we don't want the console to drop down a line when the program runs.
    str_program_exit db "Program exited normally.", 10, 0
    str_option_selected db "Option selected: ", 0
    str_invalid_option db "Invalid option, please try again.", 10, 0
    
    ;######################################## [USER DATA SECTION] #####################################################
    str_enter_surname db "Enter surname: ", 0
    str_enter_forename db "Enter forename: ", 0
    str_enter_age db "Enter age: ", 0
    str_enter_id db "Enter ID: ", 0
    str_array_full db "Can't add - storage full.", 10, 0
    str_number_of_users db "Number of users: ", 0
    
    str_enter_email db "E-mail address: ", 0
    str_enter_dept db "Department: ", 0
    
    ; The declarations below are used for labelling the print out.
    user_firstname db "First name: ", 0
    user_surname db "Surname: ", 0
    user_age db "Age: ", 0
    user_id db "User ID: ", 0
    user_email db "E-mail: ", 0
    user_dept db "Department: ", 0
    
    del_user db "User ID to delete: ", 0
    str_user_id db "User ID to search: ", 0
    user_found db "User found!", 10, 0
    user_found_del db "User found!, deleting...", 10, 0
    user_not_found db "User not found!", 10, 0
    ;################################################################################################################
    
    
    list_of_users db "********************************** [USERS] ****************************************", 10, 0
    list_of_computers db "********************************** [COMPUTERS **************************************", 10, 0
    end_decor db "************************************************************************************", 10, 0
    list_delimiter db "-----------------------------------------------------------------------------------", 10, 0
    
    ;##################################################################################################################
    
    
    ;######################################## [COMPUTER DATA SECTION] ###################################################
    str_enter_computer_name db "Enter computer name: ", 0
    str_search_computer db "Computer name to search: ", 0
    str_del_computer db "Computer name to delete: ", 0
    str_computer_ip_address db "Enter computer's IP address: ", 0
    str_computer_os db "Enter computer's OS name: ", 0
    str_main_user_uid db "Enter user ID of main user: ", 0
    str_purchase_date db "Enter date of purchase(DD/MM/YY): ", 0
    str_computer_array_full db "Can't add - storage full.", 10, 0
    str_number_of_computers db "Number of computers: ", 0
    
    ; The declarations below are used for labelling the print out.
    computer_name db "Computer name: ", 0
    computer_ip_address db "Computer IP address: ", 0
    computer_os_name db "OS: ", 0
    computer_main_uid db "User ID: ", 0
    computer_date_of_purchase db "Purchased date: ", 0 
    
    computer_found db "Computer found!", 10, 0
    computer_found_del db "Computer found!, deleting...", 10, 0
    computer_not_found db "Computer not found!", 10, 0
    del_computer db "Computer UID to delete: ", 0
    ;####################################################################################################################

    ; Here we define the size of the block of memory that we want to reserve to hold the users' details
    ; A user record stores the following fields:
    ; forename = 64 bytes (string up to 63 characters plus a null-terminator)
    ; surname = 64 bytes (string up to 63 characters plus a null-terminator)
    ; Age = 1 byte (we're assuming that we don't have any users aged over 255 years old. 
    ; Although if we entered Henry IV, this may be a problem!)
    ; User ID = 64 bytes (string up to 63 characters plus a null terminator)
    ; E-mail = 17 bytes (string up to 16 characters plus a null terminator
    ; Department = 20 bytes (string up to 20 characters plus a null terminator)

    ; Total size of user record is therefore 64+64+64+20+17+1 = 230 bytes
    size_user_record equ 230 
    max_num_users equ 100 ; 100 users maximum in array (we can make this smaller in debugging for testing array limits etc.)
    size_users_array equ size_user_record*max_num_users ; This calculation is performed at build time and is therefore hard-coded in the final executable.
    ; We could have just said something like "size_users_array equ 23000". However, this is less human-readable and more difficult to modify the number of users / user record fields.
    ; The compiled code would be identical in either case.
	
    ; Here we define the size of the block of memory that we want to reserve to hold the computers' details
    ; A computer record stores the following fields:
    ; computer name = 64 bytes (string up to 63 characters plus a null-terminator)
    ; computer's ip address = 64 bytes (string up to 63 characters plus a null-terminator)
    ; computer os name = 10 byte
    ; main user ID = 64 bytes (string up to 63 characters plus a null terminator)
    ; date of purchase =  15 bytes (We are assuming the date is in the format DD/MM/YY)
    
    ; Total size of computer record is therefore 64+64+10+64+15 = 217 bytes
    size_computer_record equ 217
    max_num_computers equ 500   ; 500 computers are the maximum the array can hold
    size_computers_array equ size_computer_record*max_num_computers ; the size of the array is computed to efficiently hold the data for the computers.
	
    current_number_of_users dq 0 ; this is a variable in memory which stores the number of users which have currently been entered into the array.
    current_number_of_computers dq 0    ; this is a variable in memory which stores the number of computers which have currently been entered into the array.
; The ".bss" section is where we define uninitialised data in memory. 
; Unlike the .data section, this data does not take up space in the executable file (apart from its definition, of course).
; Upon execution, this data is initialised to zero. This section is read/write but NOT executable, for the same reasons as .data section above.
; The syntax differs slightly from that of the .data section:
; resb = Reserve a Byte (1 byte)
; resw = Reserve a Word (2 bytes)
; resd = Reserve a Doubleword (4 bytes)
; resq = Reserve a Quadword (8 bytes)
section .bss
    users: resb size_users_array; space for max_num_users user records.
    computers: resb size_computers_array
    
; The ".text" section contains the executable code. This area of memory is generally read-only so that the code cannot be mucked about with at runtime by a mischievous user.
section .text

;################################### [ OPERATIONS ON USER DATA ] #####################################################
add_user:
; Adds a new user into the array
; We need to check that the array is not full before calling this function. Otherwise buffer overflow will occur.
; No parameters (we are using the users array as a global)
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    mov rcx, users ; base address of users array
    mov rax, QWORD[current_number_of_users] ; value of current_number_of_users
    mov rbx, size_user_record ; size_user_record is an immediate operand since it is defined at build time.
    mul rbx ; calculate address offset (returned in RAX).
    ; RAX now contains the offset of the next user record. We need to add it to the base address of users record to get the actual address of the next empty user record.
    add rcx, rax ; calculate address of next unused users record in array
    ; RCX now contins address of next empty user record in the array, so we can fill up the data.

    ; get forename
    mov rdi, str_enter_forename
    call print_string_new ; print message
    call read_string_new ; get input from user
    mov rsi, rax ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into user record in array
    ; get surname
    add rcx, 64 ; move along by 64 bytes (which is the size reserved for the forename string)
    mov rdi, str_enter_surname
    call print_string_new ; print message
    call read_string_new ; get input from user
    mov rsi, rax ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into user record in array
    ; get age
    add rcx, 64 ; move along by 64 bytes (which is the size reserved for the surname string)
    mov rdi, str_enter_age
    call print_string_new ; print message
    call read_uint_new ; get input from user
    ; inputted number is now in the RAX register
    mov BYTE[rcx], al ; we are only going to copy the least significant byte of RAX (AL), because our age field is only one byte
    ; get user id
    inc rcx ; move along by 1 byte (which is the size of age field)
    mov rdi, str_enter_id
    call print_string_new ; print message
    call read_string_new ; get input from user
    mov rsi, rax ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into user record in array

    add rcx, 64 ; move along by 64 bytes (which is the size reserved for the user id)
    mov rdi, str_enter_email    
    call print_string_new   ; print message
    call read_string_new    ; get input from user
    mov rsi, rax    ; address of new string input by the user into rsi
    mov rdi, rcx    ; address of memory slot into rdi
    call copy_string    ; copy string from input buffer into user record in array
    
    add rcx, 17 ; move along by 17 bytes (which is the size reserved fo the email)
    mov rdi, str_enter_dept 
    call print_string_new   ; print message
    call read_string_new    ; get input from user
    mov rsi, rax    ; address of new string input by the user into rsi
    mov rdi, rcx    ; address of memory slot into rdi
    call copy_string    ; copy string from input buffer into user record in array
   
    inc QWORD[current_number_of_users] ; increment our number of users counter, since we have just added a record into the array.
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function 'add_user'
;========================================================================================================
 
search_user:
; This function helps us to search for a particular user using their user id.
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, str_user_id
    call print_string_new   ; prints a label for the user id to search for.
    call read_string_new    ; collects the input from the admin.

    lea rdi, [rax]  ; loads the effective address of the user id to search for, returned by read_string_new in rax, into rdi.
    lea rsi, [users + 129]  ; loads the address of the user id into rsi. The user id starts from offset 129.
    mov rcx, [current_number_of_users]  ; we need this so that the following loop can search for all the records we have.

.start_loop:
    cmp rcx, 0
    je .not_found
    call strings_are_equal  ; returns 1 in rax if equal, 0 otherwise.
    mov rbx, rax    ; moves the returned value of strings_are_equal, which is in rax, into rbx
    cmp rbx, 1 
    je .equal
    add rsi, size_user_record   ;move to the next record
    dec rcx    ; decrement our counter.
    jmp .start_loop

.not_found:
    mov rdi, user_not_found
    call print_string_new
    jmp .finish_loop
.equal:
    mov rdi, user_found
    call print_string_new
    
    mov rdi, end_decor
    call print_string_new
    
    call print_user
    
    mov rdi, end_decor
    call print_string_new

.finish_loop:
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function 'search_user'	
;======================================================================================================== 
   
; This function prints the user we searched for. We need to print the user so that the admin
; can access specific details related to the user like the names, user ID, email address, etc.
print_user:
    push rbx
    push rcx    ; this holds the index or position in the users array, where the user was found.
    push rdx
    push rdi
    push rsi
    
    lea rsi, [users]    ; loads the effective address of the users array into rsi.
    mov rax, QWORD[current_number_of_users]
    
    sub rcx,  rax   ; We need to subtract the number of users from the index where the user was found.
    neg rcx ; the subtraction above produces negative result, so we negate rcx to get the correct absolute value.
    mov rbx, rcx    ; move the position where the id was found to rbx
    xor rcx, rcx    ; clear rcx. We will be using it and we don't want any value in it yet.
    mov rax, rbx    ; once again, move the current index into rax.
    mov rdx, 230   
    mul rdx ; perform the multiplication of rax * rdx which is, index * 230.
    lea rsi, [users + rax]  ; loads the effective address of the content of that particular index into rsi.
    
    ;display the user record
    mov rdi, user_firstname
    call print_string_new
    mov rdi, rsi ; put the pointer to the current record in RDI, to pass to the print_string_new function
    ;display forename
    call print_string_new
    call print_nl_new
    
    ;display surname
    mov rdi, user_surname
    call print_string_new
    lea rdi, [rsi + 64] ; move the pointer along by 64 bytes from the base address of the record (the size of the forename string)
    call print_string_new
    call print_nl_new
    ;display age
    mov rdi, user_age
    call print_string_new
    movzx rdi, BYTE[rsi + 128] ; dereferrence [RSI + 128] into RDI. 128 bytes is the combined size of the forename and surname strings.
                                                ;We need to zero extend (movzx) because the age in memory is one byte and the RDI register is 8 bytes.
    call print_uint_new ; print the age
    call print_nl_new
    mov rdi, user_id
    call print_string_new
    lea rdi, [rsi + 129] ; move the pointer along by 129 bytes from the base address of the record (combined size of the forename and surname strings, and age) 
    call print_string_new
    call print_nl_new
    
    mov rdi, user_email
    call print_string_new
    lea rdi, [rsi + 193]
    call print_string_new
    call print_nl_new
    
    mov rdi, user_dept
    call print_string_new
    lea rdi, [rsi + 210]
    call print_string_new
    call print_nl_new
    
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function 'print_user'	
;========================================================================================================
  
delete_user:
; This functions is used to delete a user based on their user id.
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, del_user   
    call print_string_new   ; prints the label for the user id to delete.
    call read_string_new    ; collects input about the user id to delete
    lea rdi, [rax]      ; loads the effective address of the input returned in rax, into rdi.
    lea rsi, [users + 129]  ; loads the address of the location of the user id( which starts from offset 129) in the users array into rsi.
    mov rcx, QWORD[current_number_of_users] 

.start_loop:
    cmp rcx, 0
    je .user_not_found
    call strings_are_equal  ; returns 1 if equal in rax, 0 otherwise.
    mov rbx, rax    ; moves the returned value into rbx.
    cmp rbx, 1
    je .remove_uid  ; if equal go and remove the user.
    add rsi, size_user_record   ; else, advance to the next record.
    dec rcx     ; decrement our counter
    jmp .start_loop

.user_not_found:
    mov rdi, user_not_found
    call print_string_new
    jmp .finish_loop	
.remove_uid:
    mov rdi, user_found_del
    call print_string_new
    
.start_delete_process:
    lea rsi, [users]    ; loads the effective address of the users array into rsi.
    mov rdi, rsi        ; same as 'lea rdi, [users]'
    mov rax, QWORD[current_number_of_users]
    
    ; Before the start_loop label, rcx was given the number of users record we have.
    ; looking at the start_loop label again, each time it runs, rcx holds the index or position 
    ; where the user id was found. And since it decreases from top to bottom(e.g 3,2,1)
    ; each time a search is made, we need to look for the particular  position where the user id in the users record
    ; was found. To do this,  we need to subtract the total number of users in the record from 
    ; rcx(this returns a negative value, so we negate it to get positive value). The result of this subtraction gives us
    ; the correct position of where the user id was found in the users record.
    sub rcx,  rax
    neg rcx
    mov rbx, rcx    ; move the position where the id was found to rbx
    xor rcx, rcx    ; clear rcx. We will be using it and we don't want any value in it yet.
    jmp .loop2
	
.loop1:
    ; Before going ahead, in summary what is going on in this '.loop1 label' is this:
    ; users[i] = users[i+1]
    ; I represent it using the C notation of arrays for easy understanding.
    
    mov rax, rbx    ; moves the current index of the users array record we are working on into rax.
    add rax, 1      ; adds 1 to the index
    mov rdx, 230    ; move the total size of each record( each record has a size of 230 bytes) into rdx.
    
    ; multiply the index(rax) with the total size(rdx). This is done so that we can get the content at
    ; that particular index. Note that to get the content of an array at a particular index or position, we need
    ; multiply the index by the size of the array record( In this our case, it will be 'index * 230 bytes'). So it will
    ; be the 'users + index * 193 bytes'.
    mul rdx
    lea rsi, [users + rax]  ; loads the effective address of the content of that particular index into rsi.
	
    mov rax, rbx    ; once again, move the current index into rax.
    mov rdx, 230   
    mul rdx ; perform the multiplication of rax * rdx which is, index * 230.
    lea rdi, [users + rax]  ; loads the effective address of the content of that particular index into rsi.
	
    mov rcx, 230    ; store the number of bytes to be copied, 230( which is the total size of each user record).
    cld ; clears the direction flag

.inner_loop1:
    lodsb   ; loads a byte of the data stored in the rsi register into the al register.
    stosb   ; stores the byte from the al register into the rdi register.
    loop .inner_loop1 ; loop until 230 bytes have been copied. This number is stored in rcx.
    inc rbx ; increase the index

.loop2:
    mov rax, QWORD[current_number_of_users] ; move the number of users presently in our record to rax
    
    ; since the delete action will affect the record(when a record is deleted, other records will be shifted
    ; to the left to occupy the spaces of the records that were also shifted to the left)
    ; we subtract 1 from it so that we can know the remaining 
    ; record that needs to be shifted left to occupy the position of the one that was there.
    ; for example: we have [3, 2, 5, 6]. Let's say we remove 2, this will create an empty space, [3, , 5, 6], 
    ; so, the values, 5 and 6 needs to be shifted left to occupy that space. So we now have [3,5,6].
    ; This also applies to the users record array. 
    sub rax, 1  
    
    ; rbx is our index into the users record array. 
    ; Check if it has not crossed the total number of users record we have.
    cmp rbx, rax   
    jl .loop1  ; if it is still less than the total number, jump to .loop1.
    dec QWORD[current_number_of_users]  ; since we are removing a record, the total number of records has to reduce by 1.
	
.finish_loop:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret ; End function 'delete_user'.
;========================================================================================================

list_all_users:
; Takes no parameters (users is global)
; Lists full details of all users in the array
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
	
    mov rdi, list_of_users
    call print_string_new
    
    lea rsi, [users] ; load base address of the users array into RSI. In other words, RSI points to the users array.
    mov rcx, [current_number_of_users] ; we will use RCX for the counter in our loop

    ;this is the start of our loop
  .start_loop:
    cmp rcx, 0
    je .finish_loop ; if the counter is a zero then we have finished our loop
    ;display the user record
    mov rdi, user_firstname
    call print_string_new
    mov rdi, rsi ; put the pointer to the current record in RDI, to pass to the print_string_new function
    ;display forename
    call print_string_new
    call print_nl_new
    
    ;display surname
    mov rdi, user_surname
    call print_string_new
    lea rdi, [rsi + 64] ; move the pointer along by 64 bytes from the base address of the record (the size of the forename string)
    call print_string_new
    call print_nl_new
    ;display age
    mov rdi, user_age
    call print_string_new
    movzx rdi, BYTE[rsi + 128] ; dereferrence [RSI + 128] into RDI. 128 bytes is the combined size of the forename and surname strings.
                                                ;We need to zero extend (movzx) because the age in memory is one byte and the RDI register is 8 bytes.
    call print_uint_new ; print the age
    call print_nl_new
    mov rdi, user_id
    call print_string_new
    lea rdi, [rsi + 129] ; move the pointer along by 129 bytes from the base address of the record (combined size of the forename and surname strings, and age) 
    call print_string_new
    call print_nl_new
    
    mov rdi, user_email
    call print_string_new
    lea rdi, [rsi + 193]
    call print_string_new
    call print_nl_new
    
    mov rdi, user_dept
    call print_string_new
    lea rdi, [rsi + 210]
    call print_string_new
    call print_nl_new
    
    call print_nl_new
    mov rdi, list_delimiter
    call print_string_new
    add rsi, size_user_record ; move the address to point to the next record in the array
    dec rcx ; decrement our counter variable
    jmp .start_loop ; jump back to the start of the loop (unconditional jump)
  .finish_loop:

    mov rdi, end_decor
    call print_string_new
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function list_all_users
;========================================================================================================
    
display_number_of_users:
; No parameters
; Displays number of users in list (to STDOUT)
    push rdi
    mov rdi, str_number_of_users
    call print_string_new
    mov rdi, [current_number_of_users]
    call print_uint_new
    call print_nl_new
    pop rdi    
    ret ; End function display_number_of_users
    



;######################################### [ OPERATIONS ON COMPUTER DATA ] #####################################################
add_computer:
; Adds a new computer into the array
; We need to check that the array is not full before calling this function. Otherwise buffer overflow will occur.
; No parameters (we are using the users array as a global)
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    mov rcx, computers ; base address of computers array
    mov rax, QWORD[current_number_of_computers] ; value of current_number_of_computers
    mov rbx, size_computer_record ; size_computer_record is an immediate operand since it is defined at build time.
    mul rbx ; calculate address offset (returned in RAX).
    ; RAX now contains the offset of the next computer record. 
    ; We need to add it to the base address of users record to get the actual address of the next empty user record.
    add rcx, rax ; calculate address of next unused computers record in array
    ; RCX now contains address of next empty computer record in the array, so we can fill up the data.

    ; get computer name
    mov rdi, str_enter_computer_name
    call print_string_new ; print message
    call read_string_new ; get input from user
    mov rsi, rax ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into computer record in array
    ; get ip address
    add rcx, 64 ; move along by 64 bytes (which is the size reserved for the computer name string)
    mov rdi, str_computer_ip_address
    call print_string_new ; prints the ip address
    call read_string_new ; get input from user
    mov rsi, rax ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into computer record in array
    ; get os name
    add rcx, 64 ; move along by 64 bytes (which is the size reserved for the ip address string)
    mov rdi, str_computer_os
    call print_string_new ; print message
    call read_string_new ; get input from user
    ; inputted number is now in the RAX register
    mov rsi, rax
    mov rdi, rcx
    call copy_string
    ; get user id
    add rcx, 10 ; move along by 10 byte (which is the size of the OS name field)
    mov rdi, str_main_user_uid
    call print_string_new ; print message
    call read_string_new ; get input from user
    mov rsi, rax ; address of new string into rsi
    mov rdi, rcx ; address of memory slot into rdi
    call copy_string ; copy string from input buffer into computer record in array
    ; get date purchase
    add rcx, 64 ; move along by 64 bytes (which is the size of the user id field)
    mov rdi, str_purchase_date
    call print_string_new   ; prints the purchase date
    call read_string_new    ; get input from the user
    mov rsi, rax    ; address of new string into rsi
    mov rdi, rcx    ; address of memory slot into rdi
    call copy_string    ; copy string from input buffer into computer record in array

    inc QWORD[current_number_of_computers] ; increment the number of computers counter, since we have just added a record into the array.
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function 'add_computer'.

;========================================================================================================

search_computer:
; This searches a computer based on the computer name.
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, str_search_computer    
    call print_string_new   ; prints the label for the computer to search
    call read_string_new    ; collects the computer name to search for.

    lea rdi, [rax]  ; loads the effective address of the computer name to search for into rdi. It is returned by read_string_new in rax.
    lea rsi, [computers]    ; loads the effective address of the computers array into rsi
    mov rcx, [current_number_of_computers]  ; rcx contains the current number of computers the following loop will be using.

.start_loop:
    cmp rcx, 0  ; checks if we have exhausted our search i.e if rcx = 0
    je .not_found
    call strings_are_equal
    mov rbx, rax    ; moves the returned value(in rax) of strings_are_equal into rbx for decision making processes.
    cmp rbx, 1  ; if equal or we found a match for the computer name we are looking for, go to .equal label.
    je .equal
    add rsi, size_computer_record ; else, move to the next record.
    dec rcx ; decrement our counter i.e rcx.
    jmp .start_loop

.not_found:
    mov rdi, computer_not_found
    call print_string_new   ; prints the string in computer_not_found.
    jmp .finish_loop

.equal:
    mov rdi, computer_found
    call print_string_new
        
    mov rdi, end_decor
    call print_string_new
    
    call print_computer
    
    mov rdi, end_decor
    call print_string_new

.finish_loop:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret ; End function 'search_computer'.
;========================================================================================================

print_computer:
    push rbx
    push rcx    ; this holds the index where the specific computer was found from the last operation before this function was called.
    push rdx
    push rdi
    push rsi
    
    lea rsi, [computers]    ; loads the effective address of the computers array into rsi.
    mov rax, QWORD[current_number_of_computers]
    
    sub rcx,  rax   ; We need to subtract the number of computers from the index to get the accurate location of the computer.
    neg rcx ; the subtraction above produces a negative result, so we negate rcx to get the correct absolute value.
    mov rbx, rcx    ; move the position where the id was found to rbx
    mov rax, rbx    ; once again, move the current index into rax.
    mov rdx, 217   
    mul rdx ; perform the multiplication of rax * rdx which is, index * 217.
    lea rsi, [computers + rax]  ; loads the effective address of the content of that particular index into rsi.

     ;display the computer record
    mov rdi, computer_name
    call print_string_new
    mov rdi, rsi ; put the pointer to the current record in RDI, to pass to the print_string_new function
    ;display computer name
    call print_string_new
    call print_nl_new
    mov rdi, computer_ip_address 
    call print_string_new ; prints the label for the computer's IP address
    ; display computer ip address
    lea rdi, [rsi + 64]     ; move the pointer along by 64 bytes from the base address of the record (the size of the computer name string)
    call print_string_new   ; prints the computer ip address 
    call print_nl_new
    ; display os name
    mov rdi, computer_os_name
    call print_string_new   ; prints the label for the computer OS name
    lea rdi, [rsi + 128]    ; move the pointer along by 64 bytes(the size of the IP address field)
    call print_string_new   ; prints the computer os name
    call print_nl_new
    
    ; displays the computer main user id	
    mov rdi, computer_main_uid
    call print_string_new   ; prints the label for the computer main user id
    lea rdi, [rsi + 138]    ; move the pointer along by 10 bytes(the size of the OS name string)
    call print_string_new   ; prints the computer main user id
    call print_nl_new
    
    ; displays the computer date of purchase
    mov rdi, computer_date_of_purchase
    call print_string_new   ; prints the label for the computer date of purchase
    lea rdi, [rsi + 202]    ; move the pointer along by 64 bytes(the size of the user id field)
    call print_string_new   ; prints the date of purchase
    call print_nl_new
       
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function 'print_computer'	
;========================================================================================================

delete_computer:
; This deletes a computer based on the computer's UID.
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, del_computer   ; moves the string containing the prompt to the rdi register
    call print_string_new   ; prints the prompt
    call read_string_new    ; collects input from the admin
    lea rdi, [rax]  ; loads the effective address of the input string (which is returned in rax) into rdi.
    lea rsi, [computers + 138]  ; since we are deleting based on the main user id. The main user id starts from offset 138 in the computers array record. 
    mov rcx, QWORD[current_number_of_computers]     ; loads the current number of computers into rcx so that we can be able to search properly till we find the user id.

.start_loop:
    cmp rcx, 0  ; checks if the content of rcx is zero.
    je .user_not_found  ; if it is zero, it means we searched the whole record and did not find a user with that id on the computers record.
    call strings_are_equal  ; checks if the user id entered(which we stored in rdi above) is equal with the user id we have in the computers record(stored in rsi).
    mov rbx, rax    ; the strings_are_equal returns 1 in rax if equal and 0 otherwise. So we move rax into rbx to compare.
    cmp rbx, 1  ; checks if the content of rbx is equal to 1.
    je .remove_uid  ; if it is equal, then we have a match. Jump to the remove_uid section
    add rsi, size_computer_record   ; move the address to the point to the next record in the computers array.
    dec rcx ; decrement the counter, rcx.
    jmp .start_loop

.user_not_found:
    mov rdi, computer_not_found ; move the string in the computer_not_found variable into rdi. 
    call print_string_new   ; print the string
    jmp .finish_loop	 ; go to finish loop since no match was found in the record.

.remove_uid:
    mov rdi, computer_found_del
    call print_string_new

.start_delete_process:
    lea rsi, [computers]    ; loads the effective address of the computers array into rsi
    mov rdi, rsi    ; also, move the address pointed by rsi into rdi. same as 'lea rdi, [computers]'
    mov rax, QWORD[current_number_of_computers] ; we need this to be in rax. This represents the number of computers record we presently have.
    
    ; Before the start_loop label, rcx was given the number of computers record we have.
    ; looking at the start_loop label again, each time it runs, rcx holds the index or position 
    ; where the computer user id was found. And since it decreases from top to bottom(e.g 3,2,1)
    ; each time a search is made, we need to look for the particular  position where the user id in the computer record
    ; was found. To do this,  we need to subtract the total number of computers in the record from 
    ; rcx(this returns a negative value, so we negate it to get positive value). The result of this subtraction gives us
    ; the correct position of where the main user id was found in the computer record.
    sub rcx,  rax
    neg rcx
    mov rbx, rcx    ;  move the position where the id was found to rbx
    xor rcx, rcx    ;  clear rcx to 0. We will be using it, so we don't need any value in it yet.
    jmp .loop2
	
.loop1:
    ; Before going ahead, in summary what is going on in this '.loop1 label' is this:
    ; computers[i] = computers[i+1]
    ; I represent it using the C notation of arrays for easy understanding.
    
    mov rax, rbx    ; moves the current index of the computer array record we are working on into rax.
    add rax, 1      ; adds 1 to the index
    mov rdx, 217    ; move the total size of each record into rdx.
    
    ; multiply the index(rax) with the total size(rdx). This is done so that we can get the content at
    ; that particular index. Note that to get the content of an array at a particular index or position, we need
    ; multiply the index by the size of the array record( In this our case, it will be 'index * 217 bytes'). So it will
    ; be the 'computers + index * 217 bytes'.
    mul rdx          
    lea rsi, [computers + rax]  ; loads the effective address of the content of that particular index into rsi.
	
    mov rax, rbx    ; once again, move the current index into rax.
    mov rdx, 217   
    mul rdx ; perform the multiplication of rax * rdx which is, index * 217.
    lea rdi, [computers + rax]  ; loads the effective address of the content of that particular index into rsi.
	
    mov rcx, 217    ; store the number of bytes to be copied, 217( which is the total size of each computer record).
    cld ; clears the direction flag

.inner_loop1:
    lodsb   ; loads a byte of the data stored in the rsi register into the al register.
    stosb   ; stores the byte from the al register into the rdi register.
    loop .inner_loop1 ; loop until 217 bytes have been copied. This number is stored in rcx.
    inc rbx ; increase the index

.loop2:
    mov rax, QWORD[current_number_of_computers] ; move the number of computers presently in our record to rax
    
    ; since the delete action will affect the record(when a record is deleted, other records will be shifted
    ; to the left to occupy the spaces of the records that were also shifted to the left)
    ; we subtract 1 from it so that we can know the remaining 
    ; record that needs to be shifted left to occupy the position of the one that was there.
    ; for example: we have [3, 2, 5, 6]. Let's say we remove 2, this will create an empty space, [3, , 5, 6], 
    ; so, the values, 5 and 6 needs to be shifted left to occupy that space. So we now have [3,5,6].
    ; This also applies to the computer record array. 
    sub rax, 1  
    
    ; rbx is our index into the computer record array. 
    ; Check if it has not crossed the total number of computer record we have.
    cmp rbx, rax   
    jl .loop1  ; if it is still less than the total number, jump to loop1.
    dec QWORD[current_number_of_computers]  ; since we are removing a record, the total number of records has to reduce by 1.
	
.finish_loop:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret ; End function 'delete_computer'.
;========================================================================================================

list_all_computers:
; Lists full details of all computers in the array
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, list_of_computers
    call print_string_new
    lea rsi, [computers] ; load base address of the computers array into RSI. In other words, RSI points to the computers array.
    mov rcx, [current_number_of_computers] ; we will use RCX for the counter in our loop

    ;this is the start of our loop
.start_loop:
    cmp rcx, 0
    je .finish_loop ; if the counter is a zero then we have finished our loop
    ;display the computer record
    mov rdi, computer_name
    call print_string_new
    mov rdi, rsi ; put the pointer to the current record in RDI, to pass to the print_string_new function
    ;display computer name
    call print_string_new
    call print_nl_new
    mov rdi, computer_ip_address 
    call print_string_new ; prints the label for the computer's IP address
    ; display computer ip address
    lea rdi, [rsi + 64]     ; move the pointer along by 64 bytes from the base address of the record (the size of the computer name string)
    call print_string_new   ; prints the computer ip address 
    call print_nl_new
    ; display os name
    mov rdi, computer_os_name
    call print_string_new   ; prints the label for the computer OS name
    lea rdi, [rsi + 128]    ; move the pointer along by 64 bytes(the size of the IP address field)
    call print_string_new   ; prints the computer os name
    call print_nl_new
    
    ; displays the computer main user id	
    mov rdi, computer_main_uid
    call print_string_new   ; prints the label for the computer main user id
    lea rdi, [rsi + 138]    ; move the pointer along by 10 bytes(the size of the OS name string)
    call print_string_new   ; prints the computer main user id
    call print_nl_new
    
    ; displays the computer date of purchase
    mov rdi, computer_date_of_purchase
    call print_string_new   ; prints the label for the computer date of purchase
    lea rdi, [rsi + 202]    ; move the pointer along by 64 bytes(the size of the user id field)
    call print_string_new   ; prints the date of purchase
    call print_nl_new
    call print_nl_new
    
    mov rdi, list_delimiter ; move the decorative string of dashes (-) for the display into the rdi register
    call print_string_new   ; print it
    
    add rsi, size_computer_record ; move the address to point to the next record in the array
    dec rcx ; decrement our counter variable
    jmp .start_loop ; jump back to the start of the loop (unconditional jump)
  
.finish_loop:
    mov rdi, end_decor  ; move the decorative string of asterisks for the display into the rdi register
    call print_string_new   ;print it
    pop rsi    
    pop rdi    
    pop rdx
    pop rcx
    pop rbx 
    ret ; End function 'list_all_computers'.
;========================================================================================================

display_number_of_computers:
; This displays the number of computers we have presently in our computers array record.
    push rdi
    mov rdi, str_number_of_computers    ; moves the string into the rdi for printing a label.
    call print_string_new               ; prints the string
    mov rdi, [current_number_of_computers]  ; moves the current number of cumputer we have in our record into rdi.
    call print_uint_new ; prints an unsigned integer containing the number.
    call print_nl_new   ; prints new line.
    pop rdi
    ret ; End function 'display_number_of_computers'.
;#################################################################################################################

display_main_menu:
; No parameters
; Prints main menu
    push rdi
    mov rdi, str_main_menu
    call print_string_new
    pop rdi
    ret ; End function 'display_main_menu'.
;========================================================================================================
    
display_choice:
; This displays the choice to the admin. He needs to choose either computer or user
; for his preferred operation(add, delete, search or list)
    push rdi
    mov rdi, str_make_choice
    call print_string_new
    pop rdi
    ret ; End function 'display_choice'.
;========================================================================================================

main: 
    mov rbp, rsp; for correct debugging
    ; We have these three lines for compatability only
    push rbp
    mov rbp, rsp
    sub rsp,32
    
  .menu_loop:
    call display_main_menu
    call read_int_new ; menu option (number) is in RAX
    mov rdx, rax ; store value in RDX
    ; Print the selected option back to the user
    mov rdi, str_option_selected
    call print_string_new
    mov rdi, rdx
    call print_int_new
    call print_nl_new
    ; Now jump to the correct option
    cmp rdx, 1
    je .option_1
    cmp rdx, 2
    je .option_2
    cmp rdx, 3
    je .option_3
    cmp rdx, 4
    je .option_4
    cmp rdx, 5
    je .option_5
    cmp rdx, 6
    je .option_6
    ; If we get here, the option was invalid. Display error and loop back to input option.
    mov rdi, str_invalid_option
    call print_string_new
    jmp .menu_loop

  .option_1: ; 1. Add User or computer
    call display_choice ; the admin has to decide if it is a user or computer to add
    call read_int_new   ; collects the admin choice in integer form.
    mov rdx, rax    ; moves the input into rdx for decision making processes.
    mov rdi, str_option_selected    
    call print_string_new   ; prints the label for the option selected by the admin.
    mov rdi, rdx    
    call print_int_new  ; prints the integer representing the option selected by the admin.
    call print_nl_new   
    cmp rdx, 1
    je .check_computer_array
    cmp rdx, 2
    je .check_user_array
    cmp rdx, 3
    je .option_6
    
  .check_user_array:
    ; Check that the array is not full    
    mov rdx, [current_number_of_users] ; This is indirect, hence [] to dereference
    cmp rdx, max_num_users ; Note that max_num_users is an immediate operand since it is defined at build-time
    jl .array_is_not_full ; If current_number_of_users < max_num_users then array is not full, so add new user.
    mov rdi, str_array_full ; display "array is full" message and loop back to main menu
    call print_string_new
    jmp .menu_loop
  .array_is_not_full:
    call add_user
    jmp .menu_loop
    
  .check_computer_array:
    mov rdx, [current_number_of_computers]  ; This is indirect reference, moving the current number of our records into rdx.
    cmp rdx, max_num_computers  ; is the number of record we currently have more than the maximum number we supposed to have?.
    jl .computer_array_is_not_full   ; if it is less, then go to 'computer array is not full' label and add a computer.
    mov rdi, str_array_full     ; move the string in str_array_full into rdi for printing.
    call print_string_new   ; display "array is full" message and llop back to main menu.
    jmp .menu_loop
  .computer_array_is_not_full:
     call add_computer
     jmp .menu_loop

  .option_2: ; 2. Delete a user
    call display_choice ; the admin has to decide if it is a user or computer to add
    call read_int_new   ; collects the admin choice.
    mov rdx, rax    ; moves the option selected by the admin into rdx for decision making processes.
    mov rdi, str_option_selected    
    call print_string_new   ; prints the label for the option selected by the admin
    mov rdi, rdx
    call print_int_new  ; prints the option selected.
    call print_nl_new
    cmp rdx, 1
    je .computer_del
    cmp rdx, 2
    je .user_del
    cmp rdx, 3
    je .option_6
  .computer_del:
    call delete_computer
    jmp .end2
  .user_del:
    call delete_user
  .end2:
    jmp .menu_loop
    
  .option_3: ; 3. Search a User
    call display_choice ; the admin has to decide if it is a user or computer to add
    call read_int_new   ; collects the admin choice.
    mov rdx, rax    ; moves the option selected into rdx for decision makin processes.
    mov rdi, str_option_selected    
    call print_string_new   ; prints the label for the option selected by the admin.
    mov rdi, rdx  
    call print_int_new  ; prints the option selected
    call print_nl_new
    cmp rdx, 1
    je .computer_search
    cmp rdx, 2
    je .user_search
  .computer_search:
    call search_computer
    jmp .end3
  .user_search:
     call search_user
  .end3:
     jmp .menu_loop
    
  .option_4: ; 4. List All Users
    call display_choice ; the admin has to decide if it is a user or computer to add.
    call read_int_new   ; collects the admin choice.
    mov rdx, rax    ; move the option selected into rdx for decision making processes.
    mov rdi, str_option_selected   
    call print_string_new      ; prints the label for the option selected by the admin.
    mov rdi, rdx
    call print_int_new  ; prints the option selected by the admin.
    call print_nl_new
    cmp rdx, 1
    je .list_computers
    cmp rdx, 2
    je .list_users
    cmp rdx, 3
    je .option_6
  .list_computers:
    call display_number_of_computers
    call print_nl_new
    call list_all_computers
    jmp .end4
  .list_users:
    call display_number_of_users
    call print_nl_new
    call list_all_users
  .end4:
    jmp .menu_loop
    
  .option_5: ; 5. Count Users
    call display_choice ; the admin has to decide if it is a user or computer to add
    call read_int_new   ; collects the admin choice.
    mov rdx, rax
    mov rdi, str_option_selected
    call print_string_new   ; prints the label for the option selected.
    mov rdi, rdx
    call print_int_new  ; prints the option selected.
    call print_nl_new
    cmp rdx, 1
    je .computers_count
    cmp rdx, 2
    je .users_count
    cmp rdx, 3
    je .option_6
  .computers_count:
    call display_number_of_computers
    jmp .end5
  .users_count:
    call display_number_of_users
  .end5:
    jmp .menu_loop 
    
  .option_6: ; 6. Exit
    ; In order to exit the program we just display a message and return from the main function.
    mov rdi, str_program_exit
    call print_string_new

    xor rax, rax ; return zero
    ; and these lines are for compatibility
    add rsp, 32
    pop rbp
    
    ret ; End function 'main'.

