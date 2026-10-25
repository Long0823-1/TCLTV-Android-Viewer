package io.github.long0823.tclviewer;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.*;
public final class TvConnection {
 private final ChannelConfig config;private volatile Socket active;public TvConnection(ChannelConfig c){config=c;}
 public void cancel(){Socket s=active;if(s!=null)try{s.close();}catch(IOException ignored){}}
 public String command(String command)throws IOException{try(Socket s=new Socket()){active=s;s.connect(new InetSocketAddress(config.host,config.controlPort),4000);s.setSoTimeout(command.startsWith("TUNE ")?45000:4000);OutputStream out=s.getOutputStream();out.write(("AUTH "+config.token+" "+command+"\n").getBytes(StandardCharsets.US_ASCII));out.flush();ByteArrayOutputStream line=new ByteArrayOutputStream();InputStream in=s.getInputStream();for(int i=0;i<4096;i++){int b=in.read();if(b<0)throw new EOFException("TVとの接続が切れました。");if(b==10)return line.toString("US-ASCII");line.write(b);}throw new IOException("TVからの応答が長すぎます。");}finally{active=null;}}
 public void tune(ChannelConfig.Channel ch)throws IOException{String r=command("TUNE "+config.tuner+" "+ch.onid+" "+ch.tsid+" "+ch.sid);if(!r.startsWith("OK "))throw new IOException(r.contains("busy")?"TVが選局処理中です。少し待って選び直してください。":"このサービスは現在放送されていないか、受信できません。別のチャンネルを選んでください。");}
}