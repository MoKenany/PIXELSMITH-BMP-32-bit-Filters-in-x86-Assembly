.Code
; -----------------------------------------------------------------------------
; External Declarations: Variables and Labels defined in the main program (test.asm).
; This section informs the assembler about shared data and jump targets.
; -----------------------------------------------------------------------------
;EXTRN inHandle:WORD, outHandle:WORD
;EXTRN buffer:BYTE, bufferSize:WORD
;EXTRN Exit_Success:NEAR, Exit_Failure:NEAR

; -----------------------------------------------------------------------------
; == FILTER 1: INVERT COLORS (4-bit BMP)
; Description: Inverts the 64-byte color palette and then inverts the pixel data.
; -----------------------------------------------------------------------------
Invert_Filter_Proc PROC
    ; Read/Write 64-byte color palette (Crucial for 4-bit indexed BMPs)
    READ_FILE_BLOCK inHandle, buffer, 64
    WRITE_FILE_BLOCK outHandle, buffer, 64

Invert_Read_Loop:
    ; Read a chunk of data (63000 bytes) into the buffer
    READ_FILE_BLOCK inHandle, buffer, bufferSize
    JNC invert_read_ok ; Jump if read successful (Carry Flag = 0)
    JMP Exit_Failure   ; Jump to external failure handler
invert_read_ok:
    ; Check AX (bytes read). If zero, we reached End of File (EOF).
    OR AX, AX
    JNZ invert_process_chunk
    JMP Exit_Success   ; Jump to external success handler
invert_process_chunk:
    MOV CX, AX         ; Set loop counter (CX = actual bytes read)
    MOV SI, 0          ; Reset buffer index (Source Index)
    INC blockCounter
    PRINT_STRING hashMark
Invert_Process_Loop:
    CMP SI, CX
    JAE Invert_Write_Loop ; If SI >= CX, all bytes processed, time to write
    
    ; Invert the byte using XOR 0FFh (bitwise NOT)
    XOR BYTE PTR [buffer + SI], 0FFh 
    
    INC SI
    JMP Invert_Process_Loop
Invert_Write_Loop:
    ; Write the processed chunk (SI holds the actual count written)
    WRITE_FILE_BLOCK outHandle, buffer, SI
    JMP Invert_Read_Loop ; Continue reading the next chunk
Invert_Filter_Proc ENDP

; -----------------------------------------------------------------------------
; == FILTER 2: LIGHT GREYSCALE (24-bit BMP)
; Description: Converts 24-bit BGR data to grayscale using (B+G+R) / 3 approximation.
; -----------------------------------------------------------------------------
LightGrey_Filter_Proc PROC
LightGrey_Read_Loop:
    READ_FILE_BLOCK inHandle, buffer, bufferSize
    JNC lightgrey_read_ok
    JMP Exit_Failure
lightgrey_read_ok:
    OR AX, AX
    JNZ lightgrey_process_chunk
    JMP Exit_Success
lightgrey_process_chunk:
    MOV CX, AX
    MOV SI, 0
    INC blockCounter
    PRINT_STRING hashMark
LightGrey_Process_Loop:
    CMP SI, CX
    JAE LightGrey_Write_Loop

    ; 1. Load B, G, R components and sum them up in AX
    XOR AX, AX
    MOV AL, [buffer + SI]      ; Blue (B) in AL
    XOR BX, BX
    MOV BL, [buffer + SI + 1]  ; Green (G) in BL
    ADD AX, BX                 ; AX = B + G
    MOV BL, [buffer + SI + 2]  ; Red (R) in BL
    ADD AX, BX                 ; AX = B + G + R
    
    ; 2. Grayscale Calculation: (Sum * 85) / 256           ;3 * x = 256  x=85.3333
    MOV BX, 85
    MUL BX                     ; DX:AX = AX * 85
    SHR AX, 8                  ; AX = (AX * 85) / 256 (Final gray value in AL)
    
    ; 3. Store the gray value (B=AL, G=AL, R=AL)
    MOV [buffer + SI], AL      ; Blue = Gray
    MOV [buffer + SI + 1], AL  ; Green = Gray
    MOV [buffer + SI + 2], AL  ; Red = Gray
    
    ADD SI, 3                  ; Move to the next pixel (3 bytes)
    JMP LightGrey_Process_Loop
LightGrey_Write_Loop:
    WRITE_FILE_BLOCK outHandle, buffer, SI
    JMP LightGrey_Read_Loop
LightGrey_Filter_Proc ENDP

; -----------------------------------------------------------------------------
; == FILTER 3: GREYSCALE (32-bit BGRA BMP)
; Description: Converts 32-bit BGRA data to grayscale, preserving the Alpha channel.
; -----------------------------------------------------------------------------
Grey_Filter_Proc PROC
Grey_Read_Loop:
    READ_FILE_BLOCK inHandle, buffer, bufferSize
    JNC grey_read_ok
    JMP Exit_Failure
grey_read_ok:
    OR AX, AX
    JNZ grey_process_chunk
    JMP Exit_Success
grey_process_chunk:
    MOV CX, AX
    MOV SI, 0
    INC blockCounter
    PRINT_STRING hashMark
Grey_Process_Loop:
    CMP SI, CX
    JAE Grey_Write_Loop
    
    ; Preserve the Alpha channel (Byte 3) in DH
    MOV DH, [buffer + SI + 3]

    ; 1. Calculate the Grayscale value (same as Filter 2)
    XOR AX, AX
    MOV AL, [buffer + SI]
    XOR BX, BX
    MOV BL, [buffer + SI + 1]
    ADD AX, BX
    MOV BL, [buffer + SI + 2]
    ADD AX, BX
    
    MOV BX, 85
    MUL BX
    SHR AX, 8

    ; 2. Store the gray value, restore alpha
    MOV [buffer + SI], AL
    MOV [buffer + SI + 1], AL
    MOV [buffer + SI + 2], AL
    MOV [buffer + SI + 3], DH   ; Restore Alpha channel
    
    ADD SI, 4                   ; Move to the next pixel (4 bytes)
    JMP Grey_Process_Loop
Grey_Write_Loop:
    WRITE_FILE_BLOCK outHandle, buffer, SI
    JMP Grey_Read_Loop
Grey_Filter_Proc ENDP

; -----------------------------------------------------------------------------
; == FILTER 4: BINARY (Black & White for 32-bit BGRA BMP)
; Description: Sets pixels to pure Black (0) or pure White (255) based on a threshold.
; -----------------------------------------------------------------------------
Binary_Filter_Proc PROC
Binary_Read_Loop:
    READ_FILE_BLOCK inHandle, buffer, bufferSize
    JNC binary_read_ok
    JMP Exit_Failure
binary_read_ok:
    OR AX, AX
    JNZ binary_process_chunk
    JMP Exit_Success
binary_process_chunk:
    MOV CX, AX
    MOV SI, 0
    INC blockCounter
    PRINT_STRING hashMark
Binary_Process_Loop:
    CMP SI, CX
    JAE Binary_Write_Loop

    ; 1. Calculate the Grayscale value
    XOR AX, AX
    MOV AL, [buffer + SI]
    XOR BX, BX
    MOV BL, [buffer + SI + 1]
    ADD AX, BX
    MOV BL, [buffer + SI + 2]
    ADD AX, BX
    
    MOV BX, 85
    MUL BX
    SHR AX, 8
    
    ; 2. Binary threshold check (Threshold = 90)
    CMP AL, 90
    JAE Set_White ; If AL >= 90 (bright enough), set to white
Set_Black:
    MOV BYTE PTR [buffer + SI], 0
    MOV BYTE PTR [buffer + SI + 1], 0
    MOV BYTE PTR [buffer + SI + 2], 0 ; Set B, G, R to 0 (Black)
    JMP Store_Binary_Pixel
Set_White:
    MOV BYTE PTR [buffer + SI], 255
    MOV BYTE PTR [buffer + SI + 1], 255
    MOV BYTE PTR [buffer + SI + 2], 255 ; Set B, G, R to 255 (White)
Store_Binary_Pixel:
    ; (Alpha channel is untouched, next iteration starts at the next pixel's Blue component)
    ADD SI, 4                   ; Move to the next 32-bit pixel
    JMP Binary_Process_Loop
Binary_Write_Loop:
    WRITE_FILE_BLOCK outHandle, buffer, SI
    JMP Binary_Read_Loop
Binary_Filter_Proc ENDP

PrintNumber PROC
    push ax
    push bx
    push cx
    push dx

    xor cx, cx        ; digit count
    mov bx, 10        ; base 10

convert_loop:
    xor dx, dx
    div bx            ; AX / 10 ? quotient in AX, remainder in DX
    push dx           ; remainder = digit
    inc cx
    cmp ax, 0
    jne convert_loop

print_loop:
    pop dx
    add dl, '0'       ; convert digit ? ASCII
    mov ah, 02h
    int 21h           ; print it
    loop print_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber ENDP
