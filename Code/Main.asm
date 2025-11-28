.MODEL SMALL
.STACK 100h

; -----------------------------------------------------------------------------
; 1. Includes
; -----------------------------------------------------------------------------
; Include all utility macros (Macros.inc is assumed to be in the same folder)
INCLUDE .\Macros.inc
; Include the filter procedures (this file contains all PROC/ENDP definitions)
INCLUDE .\F_PROCs.asm


.DATA
    ; --- User Interface Messages --- 
  menuMsg DB 13,10
        DB '============================================================',13,10
        DB '                  COMPUTER SCIENCE IMAGE TOOL               ',13,10
        DB '============================================================',13,10,13,10
        DB '  1) Invert Colors                (4-bit BMP)',13,10
        DB '  2) Grayscale - Light            (32-bit BMP)',13,10
        DB '  3) Grayscale - Full             (32-bit BMP)',13,10
        DB '  4) Binary Black/White           (32-bit BMP)',13,10,13,10
        DB '------------------------------------------------------------',13,10
        DB ' Select Option: $'


    successMsg DB 13,10
           DB '============================================================',13,10
           DB '                     OPERATION COMPLETED                     ',13,10
           DB '============================================================',13,10
           DB ' The output image has been generated successfully.',13,10
           DB ' You may close the program or process another file.',13,10
           DB '============================================================',13,10
           DB ' Output saved to: $'
    totalBlocksMsg DB 13,10, ' Total Blocks ( Block Size=> 61.5 KB ): $'

    failureMsg DB 13,10
           DB '============================================================',13,10
           DB '                        ERROR OCCURRED                       ',13,10
           DB '============================================================',13,10
           DB ' The system could not complete the operation.',13,10
           DB ' Possible causes:',13,10
           DB '  - Missing input.bmp',13,10
           DB '  - File permissions issue',13,10
           DB '  - Corrupted BMP file',13,10
           DB '============================================================',13,10,'$'

    invalidChoiceMsg DB 13,10
                 DB '============================================================',13,10
                 DB '                       INVALID SELECTION                     ',13,10
                 DB '============================================================',13,10
                 DB ' Please restart the program and choose a valid option.',13,10
                 DB '============================================================',13,10,'$'
                 
    processingMsg DB 13,10
              DB '------------------------------------------------------------',13,10
              DB '                      PROCESSING IMAGE                      ',13,10
              DB '------------------------------------------------------------',13,10
              DB '   Please wait while the filter is being applied...',13,10
              DB '------------------------------------------------------------',13,10
              DB '>> ','$'
              
              hashMark DB '#$' 

              

    blockCounter DW 0


    ; --- File Names ---
    inputFileName   DB 'input.bmp', 0
    outputInvert    DB 'inverted.bmp', 0
    outputLightGrey DB 'light_grey.bmp', 0
    outputGrey      DB 'grey.bmp', 0
    outputBinary    DB 'binary.bmp', 0
    
    
    ; --- File Names  For Print---
    outputInvertP    DB 'inverted.bmp',13,10,'$'
    outputLightGreyP DB 'light_grey.bmp',13,10,'$'
    outputGreyP      DB 'grey.bmp',13,10,'$'
    outputBinaryP    DB 'binary.bmp',13,10,'$'
    outputFilePtr DW ?


    ; --- File and Data Variables (Shared state with Procedures) ---
    inHandle        DW ?                ; Handle for the input file
    outHandle       DW ?                ; Handle for the output file
    header          DB 54 DUP(?)        ; Buffer for the 54-byte BMP header
    buffer          DB 63000 DUP(?)     ; The main data buffer
    bufferSize      DW 63000            ; Size of the buffer
    userChoice      DB ?                ; Stores the user's filter choice
    progressCount   DW 0

.CODE

MAIN PROC FAR
    ; Initialize Data Segment (DS) register
    mov ax, @data
    mov ds, ax

    ; --- Display Menu and Get User Input ---
    RESET_SCREEN
    PRINT_STRING menuMsg
    READ_CHAR
    mov [userChoice], al

    ; --- Route to the correct filter setup ---
    cmp al, '1'
    je  Setup_Invert
    cmp al, '2'
    je  Setup_LightGrey
    cmp al, '3'
    je  Setup_Grey
    cmp al, '4'
    je  Setup_Binary

    jmp Invalid_Choice

; --- Setup Blocks: Set the correct output filename pointer (DX) ---
Setup_Invert:
    LEA DX, outputInvert
    LEA AX,outputInvertP
    MOV outputFilePtr, AX
    
    JMP Open_Files
Setup_LightGrey:
    LEA DX, outputLightGrey
    LEA AX, outputLightGreyP
    MOV outputFilePtr, AX
    JMP Open_Files
Setup_Grey:
    LEA DX, outputGrey
    LEA AX, outputGreyP
    MOV outputFilePtr, AX
    JMP Open_Files
Setup_Binary:
    LEA DX, outputBinary
    LEA AX, outputBinaryP
    MOV outputFilePtr, AX
    JMP Open_Files

; --- Common File Handling and Filter Execution ---
Open_Files:
    PUSH DX                     ; Save output filename pointer on stack
    
    ; 1. Open Input File (Read-Only)
    OPEN_FILE_READ inputFileName
    JNC open_ok                 
    POP DX                      
    JMP Exit_Failure
open_ok:
    MOV inHandle, AX            ; Save Input File Handle
    POP DX                      ; Restore output filename pointer
    
    ; 2. Create Output File (Overwrite)
    CREATE_FILE
    JNC create_ok
    JMP Exit_Failure
create_ok:
    MOV outHandle, AX           ; Save Output File Handle

    ; 3. Read and Write the 54-byte BMP Header
    READ_FILE_BLOCK inHandle, header, 54
    WRITE_FILE_BLOCK outHandle, header, 54

    ; 4. Call the selected filter Procedure (Uses CALL instead of JMP)
    MOV AL, [userChoice]
    CMP AL, '1'
    JNE check_2
    RESET_SCREEN
    PRINT_STRING processingMsg
    CALL Invert_Filter_Proc     ; Execute Invert filter
    
check_2:
    CMP AL, '2'
    JNE check_3
    RESET_SCREEN
    PRINT_STRING processingMsg
    CALL LightGrey_Filter_Proc  ; Execute Light Grayscale filter
    
check_3:
    CMP AL, '3'
    JNE check_4
    RESET_SCREEN
    PRINT_STRING processingMsg
    CALL Grey_Filter_Proc       ; Execute Grayscale filter
    
check_4:
    RESET_SCREEN
    PRINT_STRING processingMsg
    CALL Binary_Filter_Proc     ; Execute Binary filter
    
    ; Control never returns here because the procedures exit via JMP to Exit_Success/Exit_Failure

; =============================================================================
; == PROGRAM EXIT POINTS (Defined here, used by procedures via EXTRN)        ==
; =============================================================================
Invalid_Choice:
    RESET_SCREEN            
    PRINT_STRING invalidChoiceMsg
    JMP Exit_Failure_No_Close
    
Exit_Success:
    CLOSE_HANDLE inHandle   
    CLOSE_HANDLE outHandle  
    RESET_SCREEN        
    PRINT_STRING successMsg 
    PRINT_STRING_PTR outputFilePtr
    PRINT_STRING totalBlocksMsg    
    Print_Num blockCounter  
    TERMINATE_PROGRAM 00h   

Exit_Failure:
    CLOSE_HANDLE inHandle   
    CLOSE_HANDLE outHandle  
    RESET_SCREEN            
    PRINT_STRING failureMsg    

Exit_Failure_No_Close:
    TERMINATE_PROGRAM 01h   

MAIN ENDP
END MAIN