import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final String username;

  const ChatScreen({
    super.key,
    required this.username,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _chatList = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatList();
  }



  Future<void> _loadChatList() async {
    debugPrint('================ CHAT DEBUG ================');
    debugPrint('USERNAME FROM CHAT SCREEN: "${widget.username}"');
    debugPrint('USERNAME LENGTH: ${widget.username.length}');
    debugPrint('USERNAME TRIMMED: "${widget.username.trim()}"');

    setState(() {
      _isLoading = true;
    });

    try {
      final chats = await _supabaseService.getChatList(
        username: widget.username.trim(),
      );

      debugPrint('CHAT LIST RESULT: $chats');
      debugPrint('CHAT COUNT: ${chats.length}');

      if (chats.isNotEmpty) {
        for (final chat in chats) {
          debugPrint(
            'CHAT: other=${chat['otherUsername']}, '
                'message=${chat['lastMessage']}, '
                'unread=${chat['unread']}',
          );
        }
      }

      debugPrint('============================================');

      if (!mounted) return;

      setState(() {
        _chatList = chats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CHAT ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat error: $e'),
        ),
      );
    }
  }


  void _openChat(String otherUsername) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(
          currentUsername: widget.username,
          otherUsername: otherUsername,
        ),
      ),
    ).then((_) {
      // Refresh chat list after returning.
      _loadChatList();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _chatList.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadChatList,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _chatList.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 8);
          },
          itemBuilder: (context, index) {
            final chat = _chatList[index];

            final String otherUsername =
                chat['otherUsername']?.toString() ?? '';

            final String lastMessage =
                chat['lastMessage']?.toString() ?? '';

            final String time =
            _formatChatTime(
              chat['lastMessageTime'],
            );

            final int unread =
            (chat['unread'] ?? 0) as int;

            if (otherUsername.isEmpty) {
              return const SizedBox.shrink();
            }

            return Card(
              elevation: 2,
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),



                leading: const CircleAvatar(
                  radius: 28,
                  backgroundColor:
                  Color(0xFFE8EAF6),
                  child: Icon(
                    Icons.person,
                    color: Colors.indigo,
                    size: 28,
                  ),
                ),


                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),

                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                subtitle: Padding(
                  padding:
                  const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      if (unread > 0)
                        Container(
                          margin:
                          const EdgeInsets.only(
                            left: 8,
                          ),
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                          BoxDecoration(
                            color: Colors.red,
                            borderRadius:
                            BorderRadius
                                .circular(20),
                          ),
                          child: Text(
                            '$unread',
                            style:
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),



                onTap: () {
                  _openChat(otherUsername);
                },
              ),
            );
          },
        ),
      ),
    );
  }



  String _formatChatTime(dynamic value) {
    if (value == null) {
      return '';
    }

    try {
      final dateTime = DateTime.parse(
        value.toString(),
      ).toLocal();

      final hour =
      dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour == 0
          ? 12
          : dateTime.hour;

      final minute =
      dateTime.minute.toString().padLeft(2, '0');

      final period =
      dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }
}



class ConversationPage extends StatefulWidget {
  final String currentUsername;
  final String otherUsername;

  const ConversationPage({
    super.key,
    required this.currentUsername,
    required this.otherUsername,
  });

  @override
  State<ConversationPage> createState() =>
      _ConversationPageState();
}

class _ConversationPageState
    extends State<ConversationPage> {
  final SupabaseService _supabaseService =
  SupabaseService();

  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  List<Map<String, dynamic>> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;

  RealtimeChannel? _channel;



  @override
  void initState() {
    super.initState();

    _loadMessages();
    _startRealtime();
  }



  Future<void> _loadMessages() async {
    try {
      final messages =
      await _supabaseService.getChatMessages(
        username1: widget.currentUsername,
        username2: widget.otherUsername,
      );

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();


      await _supabaseService.markMessagesAsRead(
        currentUsername: widget.currentUsername,
        otherUsername: widget.otherUsername,
      );
    } catch (e) {
      debugPrint('Error loading messages: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load messages: $e',
          ),
        ),
      );
    }
  }



  void _startRealtime() {
    final conversationId =
    _supabaseService.makeConversationId(
      widget.currentUsername,
      widget.otherUsername,
    );

    _channel = Supabase.instance.client
        .channel(
      'chat_$conversationId',
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        final newMessage =
            payload.newRecord;

        if (!mounted) return;

        final newId = newMessage['id'];


        final alreadyExists =
        _messages.any(
              (message) =>
          message['id'] == newId,
        );

        if (alreadyExists) {
          return;
        }

        setState(() {
          _messages.add(newMessage);
        });

        _scrollToBottom();

        if (newMessage['receiver_username'] ==
            widget.currentUsername) {
          _supabaseService.markMessagesAsRead(
            currentUsername:
            widget.currentUsername,
            otherUsername:
            widget.otherUsername,
          );
        }
      },
    )
        .subscribe();
  }



  Future<void> _sendMessage() async {
    final message =
    _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _supabaseService.sendChatMessage(
        senderUsername:
        widget.currentUsername,
        receiverUsername:
        widget.otherUsername,
        message: message,
      );

      _messageController.clear();


      await _loadMessages();

      if (!mounted) return;

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }



  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    );
  }



  @override
  void dispose() {
    _channel?.unsubscribe();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }



  Widget _buildProfileIcon() {
    return const CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person,
        color: Colors.indigo,
      ),
    );
  }


  Widget _buildMessage(
      Map<String, dynamic> message,
      ) {
    final bool isMe =
        message['sender_username'] ==
            widget.currentUsername;

    final String messageText =
        message['message']?.toString() ?? '';

    final String time =
    _formatMessageTime(
      message['created_at'],
    );

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin:
        const EdgeInsets.only(bottom: 12),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth:
          MediaQuery.of(context).size.width *
              0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.indigo
              : Colors.grey.shade200,
          borderRadius:
          BorderRadius.only(
            topLeft:
            const Radius.circular(16),
            topRight:
            const Radius.circular(16),
            bottomLeft:
            Radius.circular(
              isMe ? 16 : 4,
            ),
            bottomRight:
            Radius.circular(
              isMe ? 4 : 16,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Align(
              alignment:
              Alignment.centerLeft,
              child: Text(
                messageText,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              time,
              style: TextStyle(
                color: isMe
                    ? Colors.white70
                    : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }



  String _formatMessageTime(dynamic value) {
    if (value == null) {
      return '';
    }

    try {
      final dateTime =
      DateTime.parse(
        value.toString(),
      ).toLocal();

      final hour =
      dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour == 0
          ? 12
          : dateTime.hour;

      final minute =
      dateTime.minute
          .toString()
          .padLeft(2, '0');

      final period =
      dateTime.hour >= 12
          ? 'PM'
          : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,

        title: Row(
          children: [
            _buildProfileIcon(),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUsername,
                    style:
                    const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                    overflow:
                    TextOverflow.ellipsis,
                  ),

                  const Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [


          Expanded(
            child: _isLoading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : _messages.isEmpty
                ? const Center(
              child: Text(
                'No messages yet.\nStart the conversation!',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              controller:
              _scrollController,
              padding:
              const EdgeInsets.all(
                16,
              ),
              itemCount:
              _messages.length,
              itemBuilder:
                  (context, index) {
                return _buildMessage(
                  _messages[index],
                );
              },
            ),
          ),


          SafeArea(
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration:
              BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black
                        .withOpacity(
                      0.08,
                    ),
                    blurRadius: 5,
                    offset:
                    const Offset(
                      0,
                      -2,
                    ),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      _messageController,
                      textInputAction:
                      TextInputAction
                          .send,
                      onSubmitted:
                          (_) {
                        _sendMessage();
                      },
                      decoration:
                      InputDecoration(
                        hintText:
                        'Type a message...',
                        filled: true,
                        fillColor:
                        Colors.grey
                            .shade100,
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            25,
                          ),
                          borderSide:
                          BorderSide
                              .none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  CircleAvatar(
                    backgroundColor:
                    Colors.indigo,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send,
                        color:
                        Colors.white,
                        size: 20,
                      ),
                      onPressed:
                      _isSending
                          ? null
                          : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}