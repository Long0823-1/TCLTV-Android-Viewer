package io.github.long0823.tclviewer;
import android.app.Instrumentation;
import android.os.Bundle;
import android.content.Intent;
import org.videolan.libvlc.MediaPlayer;
import org.videolan.libvlc.interfaces.IMedia;
public final class SmokeTest extends Instrumentation { private String display="011";
 public void onCreate(Bundle b){super.onCreate(b);if(b!=null)display=b.getString("channel","011");start();}
 public void onStart(){Bundle out=new Bundle();MainActivity activity=null;try{
 activity=(MainActivity)startActivitySync(new Intent(getTargetContext(),MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));final MainActivity a=activity;
 java.lang.reflect.Field field=MainActivity.class.getDeclaredField("player");field.setAccessible(true);MediaPlayer player=(MediaPlayer)field.get(a);player.setVolume(0);
 java.lang.reflect.Field cf=MainActivity.class.getDeclaredField("config");cf.setAccessible(true);ChannelConfig config=(ChannelConfig)cf.get(a);ChannelConfig.Channel selected=config.channels.get(0);for(ChannelConfig.Channel ch:config.channels)if(ch.display.equals(display))selected=ch;final ChannelConfig.Channel target=selected;out.putString("channel",target.display);final java.lang.reflect.Method tune=MainActivity.class.getDeclaredMethod("tune",ChannelConfig.Channel.class);tune.setAccessible(true);runOnMainSync(()->{try{tune.invoke(a,target);}catch(Exception e){throw new RuntimeException(e);}});
 Thread.sleep(30000);IMedia media=player.getMedia();IMedia.Stats stats=media==null?null:media.getStats();java.lang.reflect.Field ef=MainActivity.class.getDeclaredField("epg");ef.setAccessible(true);TsEpg epg=(TsEpg)ef.get(a);out.putLong("eit_sections",epg.validSections);out.putInt("events",epg.snapshot().size());out.putInt("decoded_video",stats==null?0:stats.decodedVideo);out.putInt("displayed_pictures",stats==null?0:stats.displayedPictures);out.putInt("decoded_audio",stats==null?0:stats.decodedAudio);if(media!=null)media.release();if(stats==null||stats.decodedVideo<30||stats.displayedPictures<30||stats.decodedAudio<10||epg.validSections==0)throw new Exception("Playback counters below threshold");out.putString("result","PASS");runOnMainSync(a::finish);finish(-1,out);
 }catch(Throwable e){out.putString("result","FAIL "+e.toString());if(activity!=null){final MainActivity a=activity;runOnMainSync(a::finish);}finish(0,out);}}
}