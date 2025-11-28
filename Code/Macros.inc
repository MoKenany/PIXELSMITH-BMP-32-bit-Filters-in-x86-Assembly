; =============================================================================
; == MACROS.INC: DOS/BIOS Utility Macros for INT 21h and INT 10h
; =============================================================================

; --- INT 21h Macros (DOS Services) ---

; 1. PRINT_STRING: Prints a $' terminated string (AH=09h)
; Usage: PRINT_STRING message_address
PRINT_STRING MACRO message_address
    MOV AH, 09h                     ; Function: Print String
    LEA DX, message_address         ; Load string address
    INT 21h                         ; Execute
ENDM

; 2. READ_CHAR: Reads a single character from the keyboard (AH=01h)
; Returns character in AL
; Usage: READ_CHAR
READ_CHAR MACRO
    MOV AH, 01h                     ; Function: Read Character from keyboard (with echo)
    INT 21h
ENDM

; 3. CLOSE_HANDLE: Closes a file handle (AH=3Eh)
; Usage: CLOSE_HANDLE file_handle_variable
CLOSE_HANDLE MACRO file_handle
    MOV AH, 3Eh                     ; Function: Close File Handle
    MOV BX, file_handle             ; Load file handle
    INT 21h
ENDM

; 4. OPEN_FILE_READ: Opens a file for read-only access (AH=3Dh, AL=00h)
; DX must contain the filename address (NULL terminated).
; Returns handle in AX (if success) or error code (if fail).
; Usage: OPEN_FILE_READ filename_address
OPEN_FILE_READ MACRO filename_address
    MOV AH, 3Dh                     ; Function: Open File
    MOV AL, 00h                     ; Mode: Read Only
    LEA DX, filename_address        ; Load filename address
    INT 21h
ENDM

; 5. CREATE_FILE: Creates or overwrites a file (AH=3Ch, CX=00h)
; DX must contain the filename address (NULL terminated).
; Returns handle in AX (if success) or error code (if fail).
; Usage: CREATE_FILE filename_address
CREATE_FILE MACRO 
    MOV AH, 3Ch                     ; Function: Create File
    MOV CX, 00h                     ; Attribute: Normal file
    INT 21h
ENDM

; 6. READ_FILE_BLOCK: Reads a block of data from a file (AH=3Fh)
; Usage: READ_FILE_BLOCK handle, buffer_address, count
; Requires: BX = handle, DX = buffer_address, CX = count
READ_FILE_BLOCK MACRO handle, buffer_address, count
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH, 3Fh                     ; Function: Read File
    MOV BX, handle                  ; File handle
    MOV CX, count                   ; Number of bytes to read
    LEA DX, buffer_address          ; Buffer memory address
    INT 21h                         ; AX contains actual bytes read (or error)

    POP DX
    POP CX
    POP BX
ENDM

; 7. WRITE_FILE_BLOCK: Writes a block of data to a file (AH=40h)
; Usage: WRITE_FILE_BLOCK handle, buffer_address, count
; Requires: BX = handle, DX = buffer_address, CX = count
WRITE_FILE_BLOCK MACRO handle, buffer_address, count
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH, 40h                     ; Function: Write to File
    MOV BX, handle                  ; File handle
    MOV CX, count                   ; Number of bytes to write
    LEA DX, buffer_address          ; Buffer memory address
    INT 21h

    POP DX
    POP CX
    POP BX
ENDM

; 8. TERMINATE_PROGRAM: Terminates the program with an exit code (AH=4Ch)
; Usage: TERMINATE_PROGRAM exit_code (0 for success, 1 for failure)
TERMINATE_PROGRAM MACRO exit_code
    MOV AH, 4Ch                     ; Function: Terminate Program
    MOV AL, exit_code               ; Load exit code (0 or 1)
    INT 21h
ENDM

; --- INT 10h Macros (BIOS Video Services) ---

; 9. RESET_SCREEN: Sets the video mode to standard text (AH=00h, AL=03h)
; This effectively clears the screen.
RESET_SCREEN MACRO
    MOV AH, 00h                     ; Function: Set Video Mode
    MOV AL, 03h                     ; Mode 03h (Standard Text 80x25)
    INT 10h
ENDM

Print_Num MACRO num
     mov ax, num          
     call PrintNumber 
ENDM

PRINT_STRING_PTR MACRO PTRL
    mov dx, PTRL
    mov ah, 09h
    int 21h
ENDM