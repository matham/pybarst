Search.setIndex({docnames:["api","examples","ftdi","ftdi_adc","ftdi_chan","ftdi_switch","getting_started","index","installation","mcdaq","pybarst","rtv","serial","server"],envversion:52,filenames:["api.rst","examples.rst","ftdi.rst","ftdi_adc.rst","ftdi_chan.rst","ftdi_switch.rst","getting_started.rst","index.rst","installation.rst","mcdaq.rst","pybarst.rst","rtv.rst","serial.rst","server.rst"],objects:{"":{pybarst:[10,0,0,"-"]},"pybarst.core":{server:[13,0,0,"-"]},"pybarst.core.server":{BarstChannel:[13,1,1,""],BarstPipe:[13,1,1,""],BarstServer:[13,1,1,""]},"pybarst.core.server.BarstChannel":{barst_chan_type:[13,2,1,""],cancel_read:[13,3,1,""],chan:[13,2,1,""],close_channel_client:[13,3,1,""],close_channel_server:[13,3,1,""],connected:[13,2,1,""],open_channel:[13,3,1,""],parent_chan:[13,2,1,""],server:[13,2,1,""],set_state:[13,3,1,""]},"pybarst.core.server.BarstPipe":{pipe_name:[13,2,1,""],timeout:[13,2,1,""]},"pybarst.core.server.BarstServer":{barst_path:[13,2,1,""],clock:[13,3,1,""],close_manager:[13,3,1,""],close_server:[13,3,1,""],connected:[13,2,1,""],curr_dir:[13,2,1,""],get_manager:[13,3,1,""],get_version:[13,3,1,""],managers:[13,2,1,""],max_server_size:[13,2,1,""],open_server:[13,3,1,""],read_size:[13,2,1,""],write_size:[13,2,1,""]},"pybarst.ftdi":{"switch":[5,0,0,"-"],FTDIChannel:[4,1,1,""],FTDIDevice:[4,1,1,""],FTDISettings:[4,1,1,""],adc:[3,0,0,"-"]},"pybarst.ftdi.FTDIChannel":{baudrate:[4,2,1,""],chan_min_buff_in:[4,2,1,""],chan_min_buff_out:[4,2,1,""],dev_description:[4,2,1,""],dev_id:[4,2,1,""],dev_loc:[4,2,1,""],dev_serial:[4,2,1,""],dev_type:[4,2,1,""],devices:[4,2,1,""],is_full_speed:[4,2,1,""],is_high_speed:[4,2,1,""],is_open:[4,2,1,""],open_channel:[4,3,1,""],set_state:[4,3,1,""]},"pybarst.ftdi.FTDIDevice":{close_channel_server:[4,3,1,""],ft_device_baud:[4,2,1,""],ft_device_bitmask:[4,2,1,""],ft_device_mode:[4,2,1,""],ft_read_device_size:[4,2,1,""],ft_write_buff_size:[4,2,1,""],ft_write_device_size:[4,2,1,""],open_channel:[4,3,1,""],parent:[4,2,1,""],set_state:[4,3,1,""],settings:[4,2,1,""]},"pybarst.ftdi.adc":{ADCData:[3,1,1,""],ADCSettings:[3,1,1,""],FTDIADC:[3,1,1,""]},"pybarst.ftdi.adc.ADCData":{bad_count:[3,2,1,""],chan1_data:[3,2,1,""],chan1_oor:[3,2,1,""],chan1_raw:[3,2,1,""],chan1_ts_idx:[3,2,1,""],chan2_data:[3,2,1,""],chan2_oor:[3,2,1,""],chan2_raw:[3,2,1,""],chan2_ts_idx:[3,2,1,""],count:[3,2,1,""],fullness:[3,2,1,""],noref:[3,2,1,""],overflow_count:[3,2,1,""],rate:[3,2,1,""],ts:[3,2,1,""]},"pybarst.ftdi.adc.ADCSettings":{chan1:[3,2,1,""],chan2:[3,2,1,""],chop:[3,2,1,""],clock_bit:[3,2,1,""],data_width:[3,2,1,""],hw_buff_size:[3,2,1,""],input_range:[3,2,1,""],input_range_str:[3,2,1,""],lowest_bit:[3,2,1,""],max_rate:[3,2,1,""],min_rate:[3,2,1,""],num_bits:[3,2,1,""],rate_filter:[3,2,1,""],reverse:[3,2,1,""],sampling_rate:[3,2,1,""],transfer_size:[3,2,1,""]},"pybarst.ftdi.adc.FTDIADC":{get_conversion_factors:[3,3,1,""],open_channel:[3,3,1,""],read:[3,3,1,""]},"pybarst.ftdi.switch":{FTDIPin:[5,1,1,""],FTDIPinIn:[5,1,1,""],FTDIPinOut:[5,1,1,""],FTDISerializer:[5,1,1,""],FTDISerializerIn:[5,1,1,""],FTDISerializerOut:[5,1,1,""],PinSettings:[5,1,1,""],SerializerSettings:[5,1,1,""]},"pybarst.ftdi.switch.FTDIPin":{open_channel:[5,3,1,""]},"pybarst.ftdi.switch.FTDIPinIn":{cancel_read:[5,3,1,""],read:[5,3,1,""]},"pybarst.ftdi.switch.FTDIPinOut":{write:[5,3,1,""]},"pybarst.ftdi.switch.FTDISerializer":{open_channel:[5,3,1,""]},"pybarst.ftdi.switch.FTDISerializerIn":{cancel_read:[5,3,1,""],read:[5,3,1,""]},"pybarst.ftdi.switch.FTDISerializerOut":{write:[5,3,1,""]},"pybarst.ftdi.switch.PinSettings":{bitmask:[5,2,1,""],continuous:[5,2,1,""],init_val:[5,2,1,""],num_bytes:[5,2,1,""],output:[5,2,1,""]},"pybarst.ftdi.switch.SerializerSettings":{clock_bit:[5,2,1,""],clock_size:[5,2,1,""],continuous:[5,2,1,""],data_bit:[5,2,1,""],latch_bit:[5,2,1,""],num_boards:[5,2,1,""],output:[5,2,1,""]},"pybarst.mcdaq":{MCDAQChannel:[9,1,1,""]},"pybarst.mcdaq.MCDAQChannel":{cancel_read:[9,3,1,""],close_channel_client:[9,3,1,""],continuous:[9,2,1,""],direction:[9,2,1,""],init_val:[9,2,1,""],open_channel:[9,3,1,""],read:[9,3,1,""],set_state:[9,3,1,""],write:[9,3,1,""]},"pybarst.rtv":{RTVChannel:[11,1,1,""]},"pybarst.rtv.RTVChannel":{bpp:[11,2,1,""],brightness:[11,2,1,""],buffer_size:[11,2,1,""],frame_fmt:[11,2,1,""],height:[11,2,1,""],hue:[11,2,1,""],lossless:[11,2,1,""],luma_contrast:[11,2,1,""],luma_filt:[11,2,1,""],open_channel:[11,3,1,""],read:[11,3,1,""],set_state:[11,3,1,""],u_saturation:[11,2,1,""],v_saturation:[11,2,1,""],video_fmt:[11,2,1,""],width:[11,2,1,""]},"pybarst.serial":{SerialChannel:[12,1,1,""]},"pybarst.serial.SerialChannel":{baud_rate:[12,2,1,""],byte_size:[12,2,1,""],max_read:[12,2,1,""],max_write:[12,2,1,""],open_channel:[12,3,1,""],parity:[12,2,1,""],port_name:[12,2,1,""],read:[12,3,1,""],set_state:[12,3,1,""],stop_bits:[12,2,1,""],write:[12,3,1,""]},pybarst:{dep_bins:[10,4,1,""],ftdi:[4,0,0,"-"],mcdaq:[9,0,0,"-"],rtv:[11,0,0,"-"],serial:[12,0,0,"-"]}},objnames:{"0":["py","module","Python module"],"1":["py","class","Python class"],"2":["py","attribute","Python attribute"],"3":["py","method","Python method"],"4":["py","data","Python data"]},objtypes:{"0":"py:module","1":"py:class","2":"py:attribute","3":"py:method","4":"py:data"},terms:{"08b":[1,4,5],"0b00000101":1,"0b00001010":1,"0b00001011":5,"0b00001100":5,"0b00001111":[1,4],"0b00110000":5,"0b01000001":[5,9],"0b01000100":5,"0b01001000":5,"0b01001011":5,"0b01100000":5,"0b01110000":5,"0b01111010":1,"0b10010000":5,"0b10110101":1,"0b11000000":5,"0b11010000":5,"0b11111111":1,"0x0000":[1,9],"0x0001":[1,9],"0x0002":9,"0x000f":[1,6,9],"0x00ff":[1,6,9],"0x01":1,"0x021c8df8":1,"0x02269ea0":1,"0x02269ef8":[1,9],"0x02269f50":1,"0x024c06f0":12,"0x0277c3b0":1,"0x0277c830":5,"0x0277c930":5,"0x0278c6b8":3,"0x027984c8":3,"0x02c77f30":13,"0x05288d30":5,"0x052f8eb0":4,"0x052f8f30":4,"0x05328eb0":4,"0x05328f30":4,"0x05338d30":4,"0x05338db0":4,"0x054bf230":4,"0x054bf2b0":4,"0x05676718":11,"0x0f":[4,5],"0xf0":5,"0xff":[1,4,5],"1000hz":3,"1080l":1,"10hz":3,"11905hz":1,"11k":1,"1530l":1,"160x120":11,"16320l":1,"192x144":11,"197127l":[1,4,13],"1khz":3,"1mhz":5,"28v":13,"3060l":1,"320x240":11,"32640l":1,"32763l":3,"32764l":3,"32765l":3,"384x288":11,"498139398l":1,"499hz":1,"50000l":1,"510l":1,"6120l":1,"640x480":11,"65280l":1,"74hc589":5,"74hc595":5,"75hc589":5,"768x576":11,"921600l":1,"abstract":[4,13],"byte":[4,5,11,12,13],"case":[3,5,11,13],"char":[1,3,4,5,11,12],"class":[2,3,5,9,10,11,12,13],"default":[1,3,4,5,8,9,11,12,13],"final":[3,4,5,9,12],"float":[3,5,9,12],"function":[1,3,5,13],"import":[1,6,13],"int":[3,4,5,9,11,12,13],"long":[3,11,13],"new":[4,5,9,11,12,13],"return":[1,3,5,9,11,12,13],"short":[3,5,9],"switch":[1,2,4,9],"true":[1,3,4,5,9,11,13],"try":[3,4,11,13],"while":[3,4,5,6,8,9,11,12,13],For:[1,3,4,5,9,11,12,13],One:1,That:[3,9,12,13],The:[1,3,4,5,6,7,8,9,11,12,13],Then:[4,6,9,13],There:[1,5,9,13],These:5,Using:[1,7,9,13],With:[3,13],_ftdi:4,_mcdaq:[1,9],_rtv:11,_serial:12,abl:[1,3,5,8,9,11,13],about:[1,3],abov:[1,3,4,5,8],accept:3,access:13,accord:[4,5,9],accumul:[3,5,9,11],accur:13,achiev:1,acquir:[3,5,9,11],across:[4,10],activ:[1,3,4,5,9,11,12,13],actual:[1,3,4,6,12,13],adc:[2,4],adccahnnel:1,adcdata:3,adcset:[1,3,4],add:[5,9],addit:13,advers:4,affect:[4,13],after:[1,3,5,6,9,11,12,13],afterward:13,again:[1,3,4,5,9,11,13],all:[1,3,4,5,8,9,11,12,13],alloc:[1,3,4,5],allow:[3,13],alreadi:[1,4,5,9,11,12,13],also:[1,3,5,9,11,13],altern:[5,8,13],although:[3,4,5,8],altogeth:[4,11],alwai:[5,9,10,12,13],among:13,amount:[12,13],angelortv:11,ani:[1,3,4,8,12,13],anoth:[1,3,5,9,11,12,13],anymor:13,anyth:[4,9,12,13],apart:5,api:[6,7,8],appdata:8,append:4,appl:12,appropri:3,approxim:[3,11],archiv:8,argument:10,aris:[4,9,11,13],arrai:3,aspx:[9,13],assign:[4,9,11,13],associ:3,assum:[1,5],async:4,attribut:[3,4,9],auto:[1,8],automat:[1,4,8,11,13],autostart:8,avail:[1,3,4,9,13],averag:[11,13],back:[1,3,4,5,9,11,12,13],bad_count:3,bang:4,barst:[1,3,4,6,9,11,12,13],barst_chan_typ:13,barst_cor:13,barst_includ:8,barst_path:[1,4,6,13],barstchannel:[4,9,11,12,13],barstpip:13,barstserv:[1,4,5,6,8,9,11,12,13],base:[2,3,5,9,11,12,13],bat:8,baud:[4,5,12],baud_rat:12,baudrat:4,becaus:[1,3,4,11,13],becom:[1,4,13],becuas:12,been:[3,5,8,9,11,12,13],befor:[1,3,5,8,9,11,12,13],begin:3,being:[5,11,13],belong:4,below:1,better:11,between:[1,3,4,5,11,12,13],bin:10,binari:[7,9,10,13],birch:[1,3,4,5],bit:[1,3,4,5,8,9,11,12,13],bit_depth:3,bitmask:[1,4,5],black:11,block:1,board:[1,3,4,5],bool:[3,4,5,13],both:[1,3,4,5,9],bpp:11,bright:11,broken:3,buff_mask:[1,5],buffer:[1,3,4,5,9,11,13],buffer_s:[1,11],bus:[1,3,4,5],byte1:5,byte2:5,byte_s:12,bytearrai:11,cabl:[1,12],call:[3,4,5,8,9,11,12,13],callabl:[5,9],camera:[6,11],can:[1,3,4,5,6,8,9,10,11,12,13],cancel:[3,4,5,9,11,13],cancel_read:[4,5,9,13],cannot:[1,4,5,11,12,13],captur:11,caus:[1,3,5,9,11,12],cbw32:9,cbw64:9,chain:[1,5],chan1:[1,3],chan1_data:[1,3],chan1_oor:3,chan1_raw:[1,3],chan1_ts_idx:3,chan2:[1,3],chan2_data:3,chan2_oor:3,chan2_raw:3,chan2_ts_idx:3,chan:[1,4,6,9,11,13],chan_baudr:5,chan_id:[1,4,13],chan_min_buff_in:4,chan_min_buff_out:4,chang:[3,4,5,8,9],channel:[2,3,5,6,7,8,13],charact:12,check:[3,4,6,13],cheesecak:12,chop:3,chroma:11,cif_ntsc:11,cif_pal:11,client:[1,3,4,5,6,8,9,11,12,13],clock:[1,3,4,5,9,11,12,13],clock_bit:[1,3,5],clock_siz:5,clone:8,close:[1,3,4,5,6,9,11,12,13],close_channel_cli:[1,3,4,5,9,11,12,13],close_channel_serv:[1,3,4,5,6,9,11,12,13],close_manag:[1,13],close_serv:[1,6,13],closest:[1,3,5],code:[1,3,4,8],color:11,com1:12,com3:[1,12],com5:12,com:[4,8,9,13],combin:[1,5,13],come:[5,8,9],command:8,commonli:13,commun:[1,3,4,5,13],compar:3,compil:[7,9],complet:[6,12],complex:1,compos:4,comput:[0,3,5,6,7,13],computingdaq:9,concaten:3,condit:3,configur:[3,6,9],connect:[1,3,4,5,6,8,9,11,12,13],consequ:4,consid:13,consist:4,construct:13,constructor:[3,4,10],contain:[1,3,9,11,12,13],content:7,continu:[1,3,4,5,9,11,13],control:[1,3,4,5,6,9,11,12,13],convert:[3,4,8],coordin:13,copi:[8,9],core:[1,4,5,6,9,11,12],correl:13,correspond:[3,4,5,9,13],could:[3,4,5,13],count:3,cpl:[3,8],creat:[1,3,4,5,6,8,9,11,12,13],creation:[1,9,11,12,13],crystal:3,crystal_freq:3,curr_dir:13,current:[1,3,5,8,9,11,13],cycl:[5,13],cython:8,d2xx:4,daisi:[1,5],daq2:1,daq:[0,6,7],daqman:1,data:[1,3,4,5,9,11,12,13],data_bit:[1,5],data_width:[1,3],deactiv:[1,4,11,13],debug:[3,4],decreas:1,def:8,default_server_timeout:13,defin:[3,10],delet:[1,3,4,5,9,11,12,13],dep_bin:[10,13],depend:[3,4,5,9,11],depth:3,deriv:[4,13],desc:[1,3,4,5],describ:[4,8,13],descript:[4,5,9,13],design:13,desir:8,desktop:13,detail:[3,4,5,9,11,12,13],detect:3,determin:[1,5,11],dev:5,dev_descript:4,dev_id:4,dev_loc:4,dev_seri:4,dev_typ:4,devic:[2,4,6,9,10,11,13],dict:13,dictionari:13,differ:[1,3,4,11,13],digit:[3,4,5,9],direct:[1,3,9],directli:[1,3,4,5,8,13],directori:[8,13],disabl:[3,11,13],discard:[3,5,9,13],disconnect:[11,13],discov:8,disrupt:4,dll:[4,9,11],document:6,doe:[3,4,8,11,12,13],doesn:[1,3,4,5,9,11,12,13],don:[4,6],done:13,doubl:[3,13],down:[1,3,6,13],download:8,driver:[6,13],due:11,durat:13,dure:[3,10],dword:[3,4,5,11,12,13],dynam:[4,9,11],each:[1,3,4,5,9,11,12,13],echo:8,effect:[1,3,13],effici:[1,3,4],either:[3,4,5,8,9,11,13],element:[5,9],elsewher:13,emb:4,empti:[3,5,12,13],enabl:[1,3,5,11],enlarg:13,enough:[1,3,5,9,11,13],ensur:[4,11,13],enumer:[1,6,9],environment:8,equal:3,error:[1,3,4,5,9,11,12,13],estim:3,etc:[1,3,4,12,13],even:[5,11,12,13],everi:[3,4,11],everyth:12,everytim:3,exact:[1,5,12],exampl:[3,4,5,6,7,9,11,12,13],exce:[4,5,12],exceed:[11,13],except:[4,11,12,13],exe:[1,6,8,9],execut:13,exhaust:13,exist:[1,4,9,11,12,13],exit:4,express:3,extra:13,extract:8,face:4,factor:[1,3],fail:9,fairli:1,fals:[1,3,4,5,9,11,12,13],farthest:5,fashion:5,fast:[1,3,5],faster:[1,3],fastest:3,few:[3,11,12],ffmpeg:11,field:5,file:[1,6,8,9,13],filenam:8,filesmeasur:9,fill:[1,3],filter:[3,11],find:[1,3,6,8,13],fine:1,finish:[3,12],first:[1,3,4,5,6,8,9,11,13],flip:3,flush:[1,4,5,9,11,12,13],folder:[8,9],follow:[1,3,4,6,8,12],forc:[8,12,13],form:13,format:[1,4,5,11],formula:3,found:6,frame:11,frame_fmt:[1,11],freq:3,frequenc:3,frequent:[3,5,9,11],fri:12,from:[1,3,4,5,6,8,9,11,12,13],ft2232h:[1,4],ft232r:4,ft_device_baud:4,ft_device_bitmask:4,ft_device_mod:4,ft_in1:1,ft_in2:1,ft_in:1,ft_out1:1,ft_out2:1,ft_out:1,ft_read_device_s:4,ft_write_buff_s:[1,4],ft_write_device_s:4,ftd2xx:4,ftdi2:1,ftdi:[0,6,7,13],ftdiadc:[1,3,4],ftdicahnnel:1,ftdichannel:[1,3,4,5,13],ftdichip:4,ftdidevic:[3,4,5],ftdiman:[1,4,13],ftdipin:[5,9],ftdipinin:[1,4,5],ftdipinout:[4,5],ftdiseri:5,ftdiserializerin:[1,5],ftdiserializerout:[1,5],ftdiset:[3,4,5],ftwr60cba:4,full:[1,3,4,8,13],full_ntsc:[1,11],full_pal:11,fulli:13,further:[1,5,9,13],furthermor:8,gentl:[3,5,9],ges:12,get:[1,3,4,7,8,11,13],get_conversion_factor:3,get_manag:[1,4,6,13],get_vers:13,git:8,github:8,given:[4,11,13],global:[1,4,5,13],good:[1,8],got:13,grai:11,group:1,guarante:13,had:[4,13],half:3,handl:4,happen:[1,3],hardwar:[3,4,6,8],has:[1,3,4,5,8,9,11,13],have:[1,3,4,5,8,9,11,12,13],haven:12,header:[1,8],height:11,here:[3,4,5,9,12,13],high:[1,3,4,5,6,9,13],higher:[3,5],highest:3,hit:12,hold:[3,4,11,13],how:[1,3,4,6,11],howev:[1,3,4,8,9,10,11,13],htm:4,http:[4,8,9,13],hue:11,hundr:3,hw_buff_siz:[1,3],identifi:4,ignor:[4,5],imag:[1,11],immedi:[3,11],implement:13,inact:[3,4,5,11,13],inactiv:13,includ:[8,10,12],inclus:3,incorrect:[3,4,9,11],increas:[3,5,13],increment:3,independ:[4,5,9],index:[3,7],indic:[1,3,4,5,9,13],individu:[8,13],inform:[3,4,11],init_v:[1,4,5,9],initi:[1,3,4,5,9,11,12,13],input:[1,3,4,5,6,9],input_rang:3,input_range_str:3,instac:[1,6,9],instal:[4,6,7,9,11],instanc:[1,3,4,5,6,9,10,11,12,13],instanti:[3,4,13],instantli:13,instead:[3,4,5,9,11,13],integ:[5,13],interfac:[4,6,9,11,12],intern:[3,4,13],interrupt:4,invalid:3,invert:1,is_full_spe:4,is_high_spe:4,is_open:4,issu:[3,4,13],its:[1,3,4,11,13],itself:[4,8],jace:13,januari:13,just:[1,3,4,5,8,9,11,12,13],keep:1,keyword:10,kwarg:[3,4,5,9,11,12,13],larg:[1,3,13],larger:[1,3,13],last:[1,4,5,9,13],latch:5,latch_bit:[1,5],latter:5,launch:[6,8,13],least:1,leav:[1,4,5,9,11,12,13],len:[1,11],length:[3,5,12],less:[5,12,13],librari:[10,13],like:[1,3,13],limit:1,line:[1,3,4,5,6,8,9],list:[1,4,5,10],load:[4,9,11],local:[1,6,8,13],locat:[4,8],longer:3,look:[6,8,13],loopback:[1,12],lose:3,lossless:[1,11],lost:[1,3],lot:11,low:[1,5,9],lower:[1,3,4],lowest:[1,3,5,6],lowest_bit:[1,3],luckili:8,luma:11,luma_contrast:11,luma_filt:11,mai:[1,3,4,6,11,13],main:13,make:[8,9],manag:[1,6,13],mani:[5,11,13],manipul:4,manual:[8,9],mark:12,mask:[1,5,6,9],master:8,matham:8,matter:[1,5,9,11],max_rat:3,max_read:[1,12],max_server_s:[11,13],max_writ:[1,12],maximum:[3,4,5,9,12,13],mccdaq:9,mcdaq:[1,6,13],mcdaqchannel:[1,6,9,13],mean:[1,3,4,5,9,11,12,13],measur:[0,6,7,13],meet:6,mention:[3,13],menu:8,messag:[3,5,9,11,13],method:[3,4,5,9,11,12,13],mhz:5,microsoft:[8,13],middl:12,might:[3,4,5,9,11,12,13],min_rat:3,mingw:8,mingwpi:8,minimum:4,miss:[3,11],mode:[3,4],modul:[3,5,6,7,9],more:[1,3,4,5,9,11,12,13],most:[3,11,13],mostli:3,move:3,ms724284:13,msdn:13,much:[1,5,13],multipl:[3,4,6,11,12,13],multipli:3,multithread:13,must:[1,3,4,5,6,8,9,11,12,13],name:[1,6,8,12,13],necessari:4,need:[1,5,8,9,12,13],never:[4,5,13],next:[3,5],nois:3,none:[3,4,5,12,13],nonetheless:1,noref:3,notch:11,note:[1,3],notifi:13,now:[1,4,5,6,9,11,12],num_bit:[1,3],num_board:[1,5],num_byt:[1,4,5],number:[1,3,4,5,9,11,12,13],object:[1,3,4,5,9,11,12,13],occur:[4,13],odd:12,off:8,offer:13,often:3,old:11,older:[4,9,11],onc:[1,3,5,6,8,9,11,12,13],one:[1,3,4,5,8,9,11,12,13],ongo:13,onli:[1,3,4,5,8,9,10,11,12,13],open:[1,3,4,5,6,9,11,12,13],open_channel:[1,3,4,5,6,9,11,12,13],open_serv:[1,4,6,13],oper:[1,3,4,5,9,13],option:[3,13],oran:12,orang:12,order:[3,4,5,8,9,11,12],other:[1,3,4,5,6,9,11,12,13],otherwis:[1,4,5,9,13],out:[5,12],output:[1,4,5,6,9],outsid:3,over:3,overflow:1,overflow_count:3,overwritten:[9,12],own:[1,13],packag:10,packet:3,page:7,parallel:[3,4,5],paramet:[1,3,4,5,8,9,10,11,12,13],parent:[4,13],parent_chan:13,pariti:12,particular:[1,3,4,9,11,13],pass:[3,4,5,13],path:[4,8,9,10,11,13],path_to_barst:13,pattern:1,pc_name:1,per:[1,3,11],percentag:3,perform:[3,5,12,13],peripher:[1,3,4,6],permenatali:9,physic:4,pin:[3,4,5,9],pinset:[1,4,5],pint:1,pip:8,pipe:[1,3,4,5,6,8,9,11,13],pipe_nam:[1,4,6,13],pipenam:8,pixel:11,place:8,point:[1,3,4,5,13],port:[3,4,5,6,7,9,11,12,13],port_nam:[1,12],posit:10,possibl:[1,3,4,5,9,11,12,13],potenti:5,pre:[5,8],precis:13,predict:13,prefer:13,preinstal:[8,9],previou:4,previous:4,print:[1,3,5,6,9,11,12,13],process:[11,13],program:[1,6,8,9,13],project:[8,10],proper:[8,11],properti:3,provid:[4,8,11,13],put:8,pybarst:6,python27:10,python:[6,8,11],qcif_ntsc:11,qcif_pal:11,question:4,queu:[1,5,9,11,13],queue:[5,9,11,13],quickli:[1,5,11],quot:3,rais:[4,11,12,13],ram:[11,13],rang:[1,3],rate:[1,3,4,5,9,11,12],rate_filt:3,rather:8,raw8x:11,raw:[1,3,11],read:[1,3,4,5,6,9,10,11,12,13],read_len:[1,12],read_siz:13,reason:[5,13],receiv:[3,5,9,12],recent:[3,11],recogn:3,recommend:[1,4],reconnect:[11,13],record:3,recov:4,recreat:13,reduc:[1,3],reduct:3,refer:[3,4],reflect:1,regularli:3,rel:3,remain:[5,9],remot:[1,13],remov:1,reopen:13,repeat:5,repeatedli:[5,13],replic:5,repres:[5,13],represent:13,request:[3,5,9,12,13],requir:[5,6,10,13],resolv:[4,13],resourc:[11,13],respect:9,respons:4,rest:12,result:[1,3,5,9,11,13],resum:[11,13],rev1:[1,3,4,5],revers:3,rgb15:11,rgb16:11,rgb24:[1,11],rgb32:11,rgb555le:11,rgb565le:11,rgb8:11,rgba:11,row:1,rs232:12,rs485:12,rtv:[0,6,7,13],rtvchannel:[1,11,13],rtvman:1,run:[1,4,6,13],safe:[10,13],sai:13,same:[1,3,4,5,9,11],sampl:[1,3,4,5,9,11,13],sampling_r:[1,3],satisfi:5,scale:3,scheme:12,search:7,second:[1,3,4,11,13],see:[1,3,4,5,8,9,11,12,13],seem:9,seen:1,select:[3,9,11],self:[3,4,5,9,11,12,13],send:[1,3,4,5,9,11,12,13],sens:[3,9],sent:[1,3,5,9,11,13],separ:[8,9],seri:5,serial1:1,serial2:1,serial:[0,4,5,6,7,13],serialchannel:[1,12],serializerset:[1,5],serman:1,server2:1,server:[0,3,4,5,6,7,9,11,12],server_tim:13,set:[1,3,4,5,6,8,9,11,12,13],set_high:[1,5],set_low:[1,5],set_stat:[1,3,4,5,9,11,12,13],setup:8,share:[1,10],should:[1,3,4,5,8,9,11,12,13],show:[1,3],shut:[1,6,13],signific:13,sill:13,similar:[4,5,9],similarli:[4,5,9,12,13],simpl:[1,4,6],simpli:[3,8,9,12,13],simultan:[1,3,12],sinc:[1,3,5,8,9,11,12,13],singl:[1,4,5,6,9,11,12,13],size:[1,3,4,5,11,13],skip:3,sleep:[11,13],slice:5,slow:3,slower:[1,5,9],small:[3,13],smaller:3,smooth:3,softwar:[5,8,9],some:[1,4,5,6,9,13],soon:11,space:[11,12],specif:[4,8,13],specifi:[5,8,10,12,13],speed:4,ssee:3,stamp:[3,13],start:[1,3,4,5,7,8,9,11,13],startup:8,state:[1,3,4,5,9,11,12,13],still:[3,4,5,9,11,13],stop:[4,11,12,13],stop_bit:12,stop_char:12,store:[3,4],str:[3,9,11,12,13],stream:3,string:[3,4,12,13],stuck:13,sub:4,subscrib:4,subsequ:[3,5,9,13],subtractend:3,success:5,suppli:[3,4],support:[1,3,4,6,9,11,13],sure:8,sync:4,system:[3,4,5,6,8,9,11,13],tabl:1,take:[1,3,5,13],taken:3,tell:[3,5,9],termin:12,test:[1,7,11],testpip:[1,4,6,13],text:12,than:[1,3,4,5,8,12,13],the_path:1,thei:[1,3,5,9,10,12,13],them:[1,4,5,8,10,11,12],themselv:[4,5],therebi:[3,5,9,11],therefor:[1,3,4,5,8,13],thi:[1,3,4,5,8,9,10,11,12,13],third:1,those:[4,5,8,9,12,13],though:5,thought:13,thread:[3,5,9,11,12,13],through:[4,9,11,12,13],time:[1,3,4,5,9,11,12,13],timeout:[1,12,13],todai:1,too:[3,5,13],top:1,total:5,transfer_s:[1,3],transmit:12,trigger:[4,5,9,13],tupl:[3,5,9,11,12,13],turn:13,twice:3,two:[1,3,4,5,11],tying:[3,5,9,11],type:[1,3,4,5,8,13],typic:[3,5],u_satur:11,uncertainti:3,unchang:[1,4,5,9],under:[3,5,8],unicod:13,uniqu:13,univers:13,unlimit:13,unrecover:13,unsign:[3,4,5,9,11,12],unsuit:3,until:[3,5,9,11,12,13],untouch:5,updat:[3,4,5,9],upgrad:8,upon:13,usb:[1,3,4,5],use:[1,3,4,5,6,9,11,12],used:[1,3,4,5,9,10,11,12,13],user:[3,11],uses:[5,13],using:[1,3,4,5,8,9,11,12,13],utc:13,utc_tim:13,v_satur:11,val:[1,5],valid:[1,5,9],valu:[1,3,4,5,6,9,11,12,13],variabl:[3,8],variou:6,veri:[3,5],version:[1,4,8,9,11,13],video:11,video_fmt:[1,11],view:1,voltag:[1,3],wai:[3,5,9],wait:[1,3,5,9,11,12,13],want:[1,4,11],wdm:11,well:[1,3,4,5,9,12],were:[1,3,4,5,12],what:[5,9,13],whatev:12,wheel:[7,9],when:[1,3,4,5,8,9,10,11,12,13],whenev:8,where:[4,5,8,13],whether:[1,3,4,5,9,11,13],which:[1,3,4,5,9,11,12,13],white:11,whole:[4,13],wide:13,width:[1,11],win7:1,window:[8,13],within:[3,4,10],without:[5,11,13],won:[11,12,13],work:13,would:[1,3,13],write:[1,3,4,5,6,9,12,13],write_s:13,written:[1,3,4,5,8,9,12,13],wrote:5,www:[4,9],x64:10,x86:[8,13],yet:[4,13],you:[1,3,4,5,6,8,9,11,12,13],your:8,yuy24:11,zero:[3,4,12,13],zip:8},titles:["The PyBarst API","PyBarst Examples","FTDI","FTDI ADC Device","FTDI Channel and Base Classes","FTDI Switching Devices","Getting Started","Welcome to PyBarst\u2019s documentation!","Installation","Measurement Computing DAQ","PyBarst","RTV","Serial","Server"],titleterms:{"class":4,"switch":5,The:0,Using:8,adc:[1,3],api:0,barst:8,base:4,binari:8,channel:[1,4,9,11,12],compil:8,comput:[1,9],core:13,daq:[1,9],devic:[1,3,5],document:7,driver:[4,8,9,11],exampl:1,ftdi:[1,2,3,4,5],get:6,instal:8,mcdaq:9,measur:[1,9],multi:10,parallel:1,pin:1,port:1,pybarst:[0,1,3,4,5,7,8,9,10,11,12,13],requir:[4,8,9,11],rtv:[1,11],run:8,serial:[1,12],server:[1,8,13],start:6,test:8,thread:10,typic:[4,9,11,12,13],usag:[4,9,11,12,13],welcom:7,wheel:8}})