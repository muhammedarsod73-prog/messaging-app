import 'package:flutter/material.dart';
void main() => runApp(const KingChatApp());

class KingChatApp extends StatefulWidget { const KingChatApp({super.key}); @override State<KingChatApp> createState() => _KingChatAppState(); }
class _KingChatAppState extends State<KingChatApp> {
  ThemeMode mode = ThemeMode.light;
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'King Chat',
      themeMode: mode,
      theme: ThemeData(primarySwatch: Colors.teal, scaffoldBackgroundColor: const Color(0xFFECE5DD), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF075E54), foregroundColor: Colors.white)),
      darkTheme: ThemeData.dark(),
      home: HomeScreen(onToggle: () => setState(()=> mode = mode==ThemeMode.light? ThemeMode.dark: ThemeMode.light)),
    );
  }
}
class HomeScreen extends StatefulWidget { final VoidCallback onToggle; const HomeScreen({super.key, required this.onToggle}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController tab; @override void initState(){ super.initState(); tab = TabController(length: 4, vsync: this); }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('King Chat 👑', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.dark_mode), onPressed: widget.onToggle)], bottom: TabBar(controller: tab, tabs: const [Tab(text:'CHATS'), Tab(text:'STATUS'), Tab(text:'GROUPS'), Tab(text:'CALLS')])),
      body: TabBarView(controller: tab, children: [const ChatList(), StatusTab(), GroupsTab(), const CallsTab()]),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF25D366), child: const Icon(Icons.chat), onPressed: (){}),
    );
  }
}
class ChatList extends StatelessWidget {
  const ChatList({super.key});
  @override Widget build(BuildContext context){
    final chats = [{'name':'King Boss','msg':'Typing... Blue Tick ✓✓','time':'10:23 AM','unread':2,'online':true},{'name':'Rahim Vai','msg':'Online/Offline, Last Seen','time':'09:15 AM','unread':0,'online':false},{'name':'Family Group','msg':'Admin System + Invite Link','time':'Yesterday','unread':5,'online':false}];
    return ListView.separated(itemCount: chats.length, separatorBuilder: (_,__)=> const Divider(height:1), itemBuilder: (c,i){
      final ch = chats[i];
      return ListTile(
        leading: Stack(children:[CircleAvatar(backgroundColor: const Color(0xFF075E54), child: Text((ch['name'] as String)[0])), if(ch['online']==true) Positioned(right:0,bottom:0,child: Container(width:12,height:12,decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white,width:2))))]),
        title: Row(children:[Expanded(child: Text(ch['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600))), const Icon(Icons.push_pin, size:14), const Icon(Icons.volume_off, size:14)]),
        subtitle: Row(children:[const Icon(Icons.done_all, size:14, color: Colors.blue), const SizedBox(width:4), Expanded(child: Text(ch['msg'] as String))]),
        trailing: Column(children:[Text(ch['time'] as String, style: const TextStyle(fontSize:11)), if((ch['unread'] as int)>0) Container(margin: const EdgeInsets.only(top:4), padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle), child: Text('${ch['unread']}', style: const TextStyle(color: Colors.white, fontSize:11)))]),
        onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> ChatDetail(name: ch['name'] as String, online: ch['online'] as bool))),
      );
    });
  }
}
class ChatDetail extends StatefulWidget { final String name; final bool online; const ChatDetail({super.key, required this.name, required this.online}); @override State<ChatDetail> createState()=> _ChatDetailState(); }
class _ChatDetailState extends State<ChatDetail> {
  final ctrl = TextEditingController();
  List<Map<String,dynamic>> msgs = [{'text':'Assalamualaikum! King Chat Full Ready?','me':false,'time':'10:20','read':true,'star':false},{'text':'Walaikum Salam! Yes - Text+Call+Image+File, Blue Tick, Typing, Delete For Everyone, Block, Reply/Forward, Reaction, Archive/Pin, Mute, Search, Contact Sync, Status View, Group Admin, App Lock, Dark Mode, Wallpaper, Star - All Included!','me':true,'time':'10:21','read':true,'star':true}];
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(titleSpacing:0, title: Row(children:[CircleAvatar(child: Text(widget.name[0])), const SizedBox(width:8), Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(widget.name, style: const TextStyle(fontSize:16)), Text(widget.online? 'online - typing...':'last seen today', style: const TextStyle(fontSize:11))])]), actions: [IconButton(icon: const Icon(Icons.call), onPressed: ()=> ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio Call - Agora Ready'))))]),
      body: Container(color: const Color(0xFFE5DDD5), child: Column(children:[
        Expanded(child: ListView.builder(itemCount: msgs.length, padding: const EdgeInsets.all(10), itemBuilder: (c,i){
          final m = msgs[i]; return Align(alignment: m['me']? Alignment.centerRight: Alignment.centerLeft, child: GestureDetector(onLongPress: ()=> showModalBottomSheet(context: context, builder: (_)=> Wrap(children:[ListTile(leading: const Icon(Icons.reply), title: const Text('Reply'), onTap: ()=> Navigator.pop(context)), ListTile(leading: const Icon(Icons.forward), title: const Text('Forward')), ListTile(leading: Icon(m['star']? Icons.star: Icons.star_border), title: Text(m['star']? 'Unstar':'Star'), onTap: (){ setState(()=> m['star']=!m['star']); Navigator.pop(context); }), ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete for Everyone'), onTap: (){ setState(()=> msgs.removeAt(i)); Navigator.pop(context); })])), child: Container(margin: const EdgeInsets.symmetric(vertical:4), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: m['me']? const Color(0xFFDCF8C6): Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children:[Text(m['text']), Row(mainAxisSize: MainAxisSize.min, children:[Text(m['time'], style: const TextStyle(fontSize:10, color: Colors.grey)), const SizedBox(width:4), if(m['me']) Icon(m['read']? Icons.done_all: Icons.done, size:14, color: m['read']? Colors.blue: Colors.grey), if(m['star']) const Icon(Icons.star, size:10, color: Colors.amber)])]))));
        })),
        SafeArea(child: Row(children:[Expanded(child: Card(margin: const EdgeInsets.all(6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Row(children:[IconButton(icon: const Icon(Icons.emoji_emotions_outlined), onPressed: (){}), Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText:'Message', border: InputBorder.none))), IconButton(icon: const Icon(Icons.attach_file), onPressed: (){}), IconButton(icon: const Icon(Icons.camera_alt), onPressed: (){})]))), CircleAvatar(backgroundColor: const Color(0xFF25D366), child: IconButton(icon: Icon(ctrl.text.isEmpty? Icons.mic: Icons.send, color: Colors.white), onPressed: (){ if(ctrl.text.isNotEmpty){ setState(()=> msgs.add({'text':ctrl.text,'me':true,'time':'${DateTime.now().hour}:${DateTime.now().minute}','read':false,'star':false})); ctrl.clear(); }}))]))])));}
}
class StatusTab extends StatelessWidget { StatusTab({super.key}); final list = [{'name':'Rahim','text':'Alhamdulillah! Text Status','views':3},{'name':'King','text':'New Update! View List','views':12}]; @override Widget build(BuildContext context){ return ListView(children:[ListTile(leading: Stack(children:[const CircleAvatar(radius:28, child: Icon(Icons.person)), Positioned(bottom:0,right:0,child: Container(decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle), child: const Icon(Icons.add, size:18, color: Colors.white)))]), title: const Text('My Status'), subtitle: const Text('Tap to add text status')), const Divider(), const Padding(padding: EdgeInsets.all(12), child: Text('Recent updates - Text Status, View List')),...list.map((s)=> ListTile(leading: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF25D366), width:2)), child: CircleAvatar(child: Text((s['name'] as String)[0]))), title: Text(s['name'] as String), subtitle: Text('${s['text']} - ${s['views']} views'))),]); }}
class GroupsTab extends StatelessWidget { GroupsTab({super.key}); final groups = [{'name':'King Family','desc':'Family group - Desc + Invite Link','members':5},{'name':'Office Team','desc':'Work group - Admin System','members':12}]; @override Widget build(BuildContext context){ return ListView(children:[Padding(padding: const EdgeInsets.all(12), child: ElevatedButton.icon(icon: const Icon(Icons.group_add), label: const Text('Create Group - Admin System'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54), foregroundColor: Colors.white), onPressed: (){})),...groups.map((g)=> Card(margin: const EdgeInsets.symmetric(horizontal:8, vertical:4), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF075E54), child: Text((g['name'] as String)[0])), title: Text(g['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${g['desc']} - https://king.chat/${g['name']} - ${g['members']} members"), trailing: const Icon(Icons.admin_panel_settings))))]); }}
class CallsTab extends StatelessWidget { const CallsTab({super.key}); @override Widget build(BuildContext context){ return ListView(children: const [ListTile(leading: CircleAvatar(child: Icon(Icons.call)), title: Text('Rahim Vai'), subtitle: Text('Audio Call - Today 10:23 AM'), trailing: Icon(Icons.call, color: Color(0xFF25D366))), ListTile(title: Text('Security + Pro Active:', style: TextStyle(fontWeight: FontWeight.bold))), ListTile(leading: Icon(Icons.lock), title: Text('App Lock')), ListTile(leading: Icon(Icons.dark_mode), title: Text('Dark Mode')), ListTile(leading: Icon(Icons.notifications), title: Text('FCM Notification')), ListTile(leading: Icon(Icons.language), title: Text('Language Switch')), ListTile(leading: Icon(Icons.wallpaper), title: Text('Chat Wallpaper')), ListTile(leading: Icon(Icons.star), title: Text('Star Message'))]); }}
