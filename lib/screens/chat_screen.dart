import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'shared_bottom_nav.dart';
import '../api/client.dart';
import '../api/messages_api.dart';
import '../api/model_message.dart';
import '../api/auth_api.dart';
import '../api/model.dart';
import '../api/room_api.dart';
import '../utils/url_utils.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final MessagesApi _api;
  late final ApiClient _client;
  String? _roomName;

  late String _roomId;
  late String _userId;
  String _userName = 'You';

  List<MessageResponse> _msgs = [];
  DateTime? _lastFetch;
  bool _isLoading = true;

  List<UserResponse> _members = [];
  Map<String, String> _nameById = {};
  Map<String, String?> _avatarUrlById = {};

  final Map<String, String> _avatarByUserId = {};

  static const List<String> _emojis = ['🫡','😭','😂','✅','🚫'];
bool _isReacting = false;




  @override
  void initState() {
    super.initState();
    _client = ApiClient.dev();
    _api = MessagesApi(_client);

   
    _roomId = widget.roomId;
    _userId = widget.userId;

    _initMeAndLoad();
  }

Future<void> _openReactionPicker(MessageResponse m) async {
  HapticFeedback.selectionClick();

  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true, 
    builder: (ctx) {
      final sys = MediaQuery.of(ctx).padding.bottom;      // system safe area
      final kb  = MediaQuery.of(ctx).viewInsets.bottom;   // keyboard
      final bottom = (kb > 0 ? kb : sys) + 12;

      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: const _ReactionBar(emojis: ['🫡','😭','😂','✅','🚫']),
      );
    },
  );

  if (selected != null) {
    await _toggleReaction(m, selected);
  }
}


Future<void> _toggleReaction(MessageResponse m, String emoji) async {
  if (_isReacting) return;
  setState(() => _isReacting = true);
  try {
    final updated = await _api.react(
      roomId: _roomId,
      messageId: m.id,
      userId: _userId,
      emoji: emoji,
    );
    setState(() {
      final i = _msgs.indexWhere((x) => x.id == m.id);
      if (i >= 0) _msgs[i] = updated;
    });
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not add reaction')),
    );
  } finally {
    setState(() => _isReacting = false);
  }
}


  Future<void> _loadMembers() async {
    final members = await RoomApi(_client).getMembers(_roomId);
    setState(() {
      _members = members;
      _nameById = {
        for (final m in members)
          m.id: (m.id == _userId ? _userName : m.firstName),
      };
      _avatarUrlById = {for (final m in members) m.id: m.avatarImageUrl};
    });
  }

Future<void> _initMeAndLoad() async {
  try {
    final me = await AuthApi(_client).getMe();
    _userName = me.firstName;
  } catch (_) {}

  // Load members + messages
  await _loadMembers();
  await _loadInitial();

 
  try {
  final room = await RoomApi(_client).getRoom(_roomId);
  setState(() => _roomName = room.name);
} catch (_) {}

}




  Future<void> _loadInitial() async {
    try {
      final ms = await _api.list(_roomId);
      setState(() {
        _msgs = ms;
        _lastFetch = _msgs.isNotEmpty ? _msgs.last.timestamp : null;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pollNew() async {
    try {
      final ms = await _api.list(_roomId, after: _lastFetch);
      if (ms.isNotEmpty) {
        setState(() {
          _msgs.addAll(ms);
          _lastFetch = _msgs.last.timestamp;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final sent = await _api.send(
        roomId: _roomId,
        senderId: _userId,
        senderName: _userName,
        content: text,
      );
      setState(() => _msgs.add(sent));
      _scrollToBottom();
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ----- helpers -----

  ChatMessage _toUi(MessageResponse m) {
    final displayName = _nameById[m.senderId] ?? m.senderName;
    final url = _avatarUrlById[m.senderId];
    final avatar = url ?? 'avatar_1.png';
    return ChatMessage(
      id: m.id,
      sender: displayName,
      message: m.content,
      time: _formatTime(m.timestamp),
      avatar: avatar,
      isCurrentUser: m.senderId == _userId,
    );
  }

  String _formatTime(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'pm' : 'am';
    return '$hour12:$minute$period';
  }

  Widget _emptyMessages() {
    return const Center(
      child: Text(
        'No messages yet ✨',
        style: TextStyle(
          fontFamily: AppFonts.darkerGrotesque,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF666666),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _msgs.isEmpty
                      ? _emptyMessages()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _msgs.length,
                        itemBuilder: (context, index) {
  final src = _msgs[index];
  return _buildMessageBubble(_toUi(src), src);
},

                        ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
      bottomNavigationBar: SharedBottomNav(
        currentIndex: 3,
        roomId: _roomId,
        userId: _userId,
        shouldPop: false,
      ),
    );
  }



  

Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: const BoxDecoration(
      color: AppColors.primaryBlue,
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _roomName ?? 'Room Chat',
            style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}


Widget _buildMessageBubble(ChatMessage message, MessageResponse src) {
  return GestureDetector(
    onLongPress: () => _openReactionPicker(src), // 👈 long-press
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isCurrentUser) ...[
            _avatar(message.avatar),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  message.isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
               
                Text(
                  message.sender,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isCurrentUser ? AppColors.primaryBlue : const Color(0xFFF8C063),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: message.isCurrentUser ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // time
                Text(
                  message.time,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                
                _reactionRow(src, isMine: message.isCurrentUser),
              ],
            ),
          ),
          if (message.isCurrentUser) ...[
            const SizedBox(width: 8),
            _avatar(message.avatar),
          ],
        ],
      ),
    ),
  );
}


Widget _reactionRow(MessageResponse m, {required bool isMine}) {
  // counts
  final counts = <String, int>{ for (final e in _emojis) e: 0 };
  for (final r in m.reactions) {
    if (counts.containsKey(r.emoji)) counts[r.emoji] = counts[r.emoji]! + 1;
  }

  // my reaction
  final myReaction = m.reactions.firstWhere(
    (r) => r.userId == _userId,
    orElse: () => Reaction(userId: '', emoji: ''),
  ).emoji;

  final chips = <Widget>[];
  for (final e in _emojis) {
    final c = counts[e]!;
    if (c == 0) continue;
    final selected = myReaction == e;

    chips.add(GestureDetector(
      onTap: () => _toggleReaction(m, e),
      child: Container(
        margin: const EdgeInsets.only(right: 6, left: 0, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withOpacity(0.15)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$c',
              style: const TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontSize: 12,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  if (chips.isEmpty) return const SizedBox.shrink();

  return Align(
    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
    child: Wrap(
      spacing: 0,
      runSpacing: 4,
      alignment: isMine ? WrapAlignment.end : WrapAlignment.start,
      children: isMine ? chips.reversed.toList() : chips, // looks nicer on right
    ),
  );
}




  Widget _avatar(String avatar) {
    final isNetworkPath = avatar.startsWith('http') || avatar.startsWith('/');
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.primaryBlue),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isNetworkPath
            ? Image.network(
                absoluteUrl(avatar), // handles leading “/”
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/avatar_1.png',
                    fit: BoxFit.cover),
              )
            : Image.asset('assets/images/$avatar', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {/* attachments later */},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.camera_alt,
                  color: Color(0xFF666666), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 16,
                  color: AppColors.black,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type your message',
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.send, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  final List<String> emojis;
  const _ReactionBar({required this.emojis});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis
                .map((e) => GestureDetector(
                      onTap: () => Navigator.pop(context, e),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}



// Simple UI model
class ChatMessage {
  final String id;
  final String sender;
  final String message;
  final String time;
  final String avatar;
  final bool isCurrentUser;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.time,
    required this.avatar,
    required this.isCurrentUser,
  });
}
