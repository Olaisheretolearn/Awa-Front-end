import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Sample chat messages
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      sender: 'Ola',
      message: 'Hey guys, anyone know who left the blender unwashed again',
      time: '10:25am',
      avatar: 'avatar_1.png',
      isCurrentUser: true,
    ),
    ChatMessage(
      id: '2',
      sender: 'Jim',
      message: 'I was rushing to class - my bad!',
      time: '10:25am',
      avatar: 'avatar_3.png',
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '3',
      sender: 'Bob',
      message: 'Can we add paper towels to the shopping list, that banana you blended is haunting us across surfaces😅',
      time: '10:26am',
      avatar: 'avatar_5.png',
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '4',
      sender: 'Christine',
      message: 'Added paper towels also added exorcism kit" in case banana dtrikes again',
      time: '10:26am',
      avatar: 'avatar_2.png',
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '5',
      sender: 'Jim',
      message: 'Lol lmao thanks',
      time: '10:27am',
      avatar: 'avatar_3.png',
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '6',
      sender: 'Bob',
      message: 'Soda added paper towels',
      time: '',
      avatar: 'avatar_5.png',
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '7',
      sender: 'Christine',
      message: 'Also me after morning walk, clean apadki and close the door man',
      time: '10:28am',
      avatar: 'avatar_2.png',
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '8',
      sender: 'Jim',
      message: 'Yeah lol 😂',
      time: '10:28am',
      avatar: 'avatar_3.png',
      isCurrentUser: false,
    ),
    ChatMessage(
      id: '9',
      sender: 'Bob',
      message: 'Also me when I check my record notes when someone does a chore',
      time: '10:28am',
      avatar: 'avatar_5.png',
      isCurrentUser: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: 'Ola',
            message: _messageController.text.trim(),
            time: _formatTime(DateTime.now()),
            avatar: 'avatar_1.png',
            isCurrentUser: true,
          ),
        );
      });
      _messageController.clear();
      _scrollToBottom();
    }
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'pm' : 'am';
    return '${hour}:${minute}$period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2),
            Color(0xFF357ABD),
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/avatar_1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '122 Celtic Bay',
              style: TextStyle(
                fontFamily: AppFonts.darkerGrotesque,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isCurrentUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/${message.avatar}',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isCurrentUser 
                        ? AppColors.primaryBlue 
                        : const Color(0xFFF8C063),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: message.isCurrentUser 
                          ? AppColors.white 
                          : AppColors.black,
                    ),
                  ),
                ),
                if (message.time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: const TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (message.isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/${message.avatar}',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Handle camera/attachment
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Color(0xFF666666),
                size: 20,
              ),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: const Icon(
                Icons.send,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF0F0F0)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, "Home", false),
            _buildNavItem(Icons.shopping_bag, "Shopping", false),
            _buildNavItem(Icons.attach_money, "Bills", false),
            _buildNavItem(Icons.chat_bubble_outline, "Chat", true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.white : const Color(0xFF666666),
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.darkerGrotesque,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryBlue : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

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