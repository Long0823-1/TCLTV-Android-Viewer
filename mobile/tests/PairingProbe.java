package io.github.long0823.tclviewer;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
public class PairingProbe {
 public static void main(String[] args)throws Exception {String wrong=String.format(java.util.Locale.ROOT,"%06d",(Integer.parseInt(args[1])+1)%1000000);boolean denied=false;try{PairingClient.fetch(args[0],wrong);}catch(java.io.IOException e){denied=true;}if(!denied)throw new AssertionError("Incorrect PIN accepted");ChannelConfig c=PairingClient.fetch(args[0],args[1]);if(c.channels.size()<1||!c.host.equals(args[0]))throw new AssertionError("Missing channel catalog");c.tuner=0;Files.write(Paths.get(args[2]),c.toIni().getBytes(StandardCharsets.UTF_8));boolean replayDenied=false;try{PairingClient.fetch(args[0],args[1]);}catch(java.io.IOException e){replayDenied=true;}if(!replayDenied)throw new AssertionError("Pairing code reused");System.out.println("PASS: incorrect PIN denied, channels="+c.channels.size()+", host set, code single-use");}
}