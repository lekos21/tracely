import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // No need to load chat history - using client-side persistence
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF7ED), // orange-50
              Color(0xFFFDF2F8), // pink-50  
              Color(0xFFFEF3E2), // peach-100
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Start a conversation!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tell me something about your partner\nor ask for suggestions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        // Sleek loading indicator (no bubble), full-width style like AI message
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: const [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Color(0xFF6B73FF),
                                    child: Icon(
                                      Icons.smart_toy,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Assistant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Sto pensando...',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      final message = _messages[index];
                      return ChatBubble(message: message);
                    },
                  ),
              ),
              // Input area (glassmorphism + gradient send button)
              ClipRRect(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.4),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Gradient circular send button
                      GestureDetector(
                        onTap: _isLoading ? null : _sendMessage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFFF472B6), Color(0xFFFB923C)],
                                  ),
                            color: _isLoading ? Colors.grey.shade400 : null,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFB923C).withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Add user message immediately
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();

    try {
      // Prepare conversation history for context
      final conversationHistory = _messages.map((msg) => {
        'text': msg.text,
        'isUser': msg.isUser,
        'timestamp': msg.timestamp.toIso8601String(),
      }).toList();
      
      // Use the new client-side chat approach
      final response = await FirebaseService().chatWithContext(
        message: text,
        conversationHistory: conversationHistory,
      );
      
      if (response['success'] == true) {
        // Add AI response
        setState(() {
          _messages.add(ChatMessage(
            text: response['response'] ?? 'Ricevuto!',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        // Handle API error
        setState(() {
          _messages.add(ChatMessage(
            text: response['response'] ?? 'Si è verificato un errore. Riprova.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      // Handle connection error
      setState(() {
        _messages.add(ChatMessage(
          text: 'Errore di connessione. Controlla la tua connessione internet.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      print('Error sending message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: message.isUser
          // USER: light peach bubble aligned to the right
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFED7AA), // more orangy peach
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Color(0xFF2A2A2A),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            )
          // AI: full-width markdown (no bubble), symmetric on page width
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Optional small AI indicator row (subtle)
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF6B73FF),
                      child: Icon(
                        Icons.smart_toy,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Assistant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  // keep same horizontal padding as list padding to align nicely
                  padding: EdgeInsets.zero,
                  child: MarkdownBody(
                    data: message.text,
                    selectable: true,
                    onTapLink: (text, href, title) async {
                      if (href == null) return;
                      final uri = Uri.tryParse(href);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(fontSize: 16, color: Color(0xFF2A2A2A)),
                      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        border: Border(left: BorderSide(color: Colors.grey, width: 3)),
                      ),
                      listBullet: const TextStyle(color: Color(0xFF2A2A2A)),
                      a: const TextStyle(color: Color(0xFF2563EB), decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
