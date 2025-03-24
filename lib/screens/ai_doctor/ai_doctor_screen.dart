import 'package:flutter/material.dart';
import 'package:elderly_care/services/ai_doctor_service.dart';

class AIDoctorScreen extends StatefulWidget {
  const AIDoctorScreen({super.key});

  @override
  State<AIDoctorScreen> createState() => _AIDoctorScreenState();
}

class _AIDoctorScreenState extends State<AIDoctorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final AIDoctorService _aiService = AIDoctorService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(const ChatMessage(
      text: "Hello! I'm your AI medical assistant. While I can provide general health information and guidance, please remember that I'm not a replacement for professional medical care. How can I help you today?",
      isUser: false,
    ));
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(
        text: text,
        isUser: true,
      ));
      _isLoading = true;
    });

    try {
      final response = await _aiService.getResponse(text);
      
      if (mounted) {
        setState(() {
          _messages.insert(0, ChatMessage(
            text: response,
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.insert(0, const ChatMessage(
            text: "I apologize, but I encountered an error. Please try again later.",
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Health Assistant',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            // Help instructions card
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Type your health question below and tap the SEND button',
                          style: TextStyle(fontSize: 18, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _messages.length,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemBuilder: (context, index) => _messages[index],
              ),
            ),
            
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Getting your answer...',
                      style: TextStyle(fontSize: 18, color: Colors.teal),
                    ),
                  ],
                ),
              ),
              
            const Divider(height: 1, thickness: 1),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Type your question here:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Example: What helps with headaches?',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                    maxLines: 2,
                    minLines: 1,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _handleSubmitted(_messageController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.send, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'SEND',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.medical_services, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12.0),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isUser ? 'You' : 'Health Assistant',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isUser ? Colors.grey[700] : Colors.teal,
                    ),
                  ),
                ),
                Material(
                  borderRadius: BorderRadius.circular(16.0),
                  color: isUser
                      ? Colors.blue[100]
                      : Colors.teal[50],
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12.0),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, color: Colors.black87, size: 28),
            ),
          ],
        ],
      ),
    );
  }
}