import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/society_api_services.dart'; // 🔄 Redirected to split Society worker layer

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color chatBg = Color(0xFFF1F3F9);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _messagesHistory = [];
  bool _isLoading = true;
  String? _residentId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_residentId == null) {
      final Map<String, dynamic> routeArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      // Safely captures the resident's primary ID from navigation arguments
      _residentId = (routeArgs['resident_id'] ?? routeArgs['id'] ?? '0')
          .toString();
      _loadLiveMessages();
    }
  }

  /// Synchronizes active back-end message matrices with your database
  Future<void> _loadLiveMessages() async {
    if (_residentId == null) return;
    try {
      final messages = await SocietyApiService.fetchChatRoomPayload(
        _sessionToken,
        _residentId!,
      );
      if (mounted) {
        setState(() {
          _messagesHistory = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String residentName = routeArgs['resident_name'] ?? 'Society Member';
    final String unitInfo = routeArgs['unit_info'] ?? 'Zenith Flat';

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              radius: 18,
              child: Text(
                residentName.isNotEmpty ? residentName[0].toUpperCase() : 'M',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    residentName,
                    style: GoogleFonts.lexend(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    unitInfo,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: chatBg,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messagesHistory.length,
                      itemBuilder: (context, index) {
                        final chatBubble = _messagesHistory[index];
                        return _buildChatBubble(chatBubble);
                      },
                    ),
                  ),
                ),
                _buildMessageInputConsole(),
              ],
            ),
    );
  }

  Widget _buildChatBubble(dynamic chatBubble) {
    // Standardizes handling for backend boolean or map structures safely
    bool isMe =
        chatBubble['is_me'] ?? (chatBubble['sender_role'] == 'CHAIRMAN');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              chatBubble['text'] ?? chatBubble['message_body'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isMe ? Colors.white : darkText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chatBubble['timestamp'] ??
                  chatBubble['formatted_time'] ??
                  'Recent',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color: isMe ? Colors.white70 : Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputConsole() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9F2), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _messageController,
                style: GoogleFonts.inter(fontSize: 13.5, color: darkText),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Send message to resident...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.black38,
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: lightBg,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: primaryBlue,
                size: 24,
              ),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final String cleanText = _messageController.text.trim();
    if (cleanText.isEmpty || _residentId == null) return;

    _messageController.clear();

    // 🔄 Post the direct message to your live backend endpoint
    bool sent = await SocietyApiService.sendDirectResidentMessage(
      token: _sessionToken,
      residentId: _residentId!,
      messageText: cleanText,
    );

    if (sent) {
      _loadLiveMessages(); // Hot-reloads chat stream view dynamically
    }
  }
}
