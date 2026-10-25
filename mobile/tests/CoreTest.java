package io.github.long0823.tclviewer;
import java.nio.file.*;
import java.nio.charset.*;
public class CoreTest {
 public static void main(String[] args)throws Exception {
  if(!AribText.decode(new byte[]{14,65,66,67},0,4).equals("ABC"))throw new AssertionError("ASCII locking shift");
  byte[] jis="日本語".getBytes(Charset.forName("EUC-JP"));for(int i=0;i<jis.length;i++)jis[i]&=127;if(!AribText.decode(jis,0,jis.length).equals("日本語"))throw new AssertionError("Kanji");
  if(!AribText.decode(new byte[]{0x7a,0x56},0,2).equals("[字]"))throw new AssertionError("Programme symbol");
  ChannelConfig c=ChannelConfig.parse(Files.readAllBytes(Paths.get(args[0])));ChannelConfig copy=ChannelConfig.parse(c.toIni().getBytes(StandardCharsets.UTF_8));if(c.channels.size()!=copy.channels.size())throw new AssertionError("INI round trip");
  boolean rejected=false;try{ChannelConfig.parse(c.toIni().replace(c.token,c.token+c.token).getBytes(StandardCharsets.UTF_8));}catch(Exception e){rejected=true;}if(!rejected)throw new AssertionError("Oversized key");
  TsEpg epg=new TsEpg();byte[] ts=Files.readAllBytes(Paths.get(args[1]));for(int off=0;off+188<=ts.length;off+=188)epg.feed(ts,off);
  System.out.println("channels="+c.channels.size()+" EIT_sections="+epg.validSections+" crc_errors="+epg.crcErrors+" events="+epg.snapshot().size());int shown=0;for(TsEpg.Event e:epg.snapshot())if(shown++<8)System.out.println(e.channelKey()+" "+java.time.Instant.ofEpochMilli(e.start)+" "+e.title+" detail_chars="+e.description.length());
  if(epg.validSections==0||epg.snapshot().isEmpty()||epg.crcErrors!=0)throw new AssertionError("Real EIT reception");System.out.println("Core tests passed.");
 }
}