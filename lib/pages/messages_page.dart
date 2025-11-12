import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({
    super.key,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? selectedReceiverId; // Track selected receiver for messages

  bool inChat = false;

  // ScrollController for the messages ListView
  final ScrollController _messagesScrollController = ScrollController();
  // ScrollController for the chat ListView (if needed)
  final ScrollController _chatScrollController = ScrollController();

  // Dummy data for profiles that sent likes
  final List<Map<String, dynamic>> dummyLikes = [
    {
      'userId': 'user1',
      'name': 'Alice Smith',
      'profileImage': 'https://via.placeholder.com/150', // Placeholder image
    },
    {
      'userId': 'user2',
      'name': 'Bob Johnson',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user3',
      'name': 'Charlie Brown',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user4',
      'name': 'Diana Lee',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user1',
      'name': 'Alice Smith',
      'profileImage': 'https://via.placeholder.com/150', // Placeholder image
    },
    {
      'userId': 'user2',
      'name': 'Bob Johnson',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user3',
      'name': 'Charlie Brown',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user4',
      'name': 'Diana Lee',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user1',
      'name': 'Alice Smith',
      'profileImage': 'https://via.placeholder.com/150', // Placeholder image
    },
    {
      'userId': 'user2',
      'name': 'Bob Johnson',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user3',
      'name': 'Charlie Brown',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user4',
      'name': 'Diana Lee',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user1',
      'name': 'Alice Smith',
      'profileImage': 'https://via.placeholder.com/150', // Placeholder image
    },
    {
      'userId': 'user2',
      'name': 'Bob Johnson',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user3',
      'name': 'Charlie Brown',
      'profileImage': 'https://via.placeholder.com/150',
    },
    {
      'userId': 'user4',
      'name': 'Diana Lee',
      'profileImage': 'https://via.placeholder.com/150',
    },
  ];

  int messageCount = 16;

  Future<void> sendMessage(String receiverId, String text) async {
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   final chatId = [user.uid, receiverId]..sort();
    //   final chatRoomId = '${chatId[0]}_${chatId[1]}';
    //   await FirebaseFirestore.instance
    //       .collection('messages')
    //       .doc(chatRoomId)
    //       .collection('messages')
    //       .add({
    //     'senderId': user.uid,
    //     'receiverId': receiverId,
    //     'text': text,
    //     'timestamp': FieldValue.serverTimestamp(),
    //   });
    //   _controller.clear();
    // }
  }

  void _sendMessage() {
    // if (_controller.text.isNotEmpty && selectedReceiverId != null) {
    //   sendMessage(selectedReceiverId!, _controller.text);
    // }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _messagesScrollController.dispose(); // Dispose the ScrollController
    _chatScrollController.dispose(); // Dispose the chat ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [

            if(!inChat)
            Expanded(
              child: Column(
                children: [
 
                  /////////////////////////////////////////////////
                  // Likes Received Section and Like List Button //
                  /////////////////////////////////////////////////

                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 15, top: 15, bottom: 15),
                          child: const Text(
                            'Likes Received',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // IconButton(
                        //   icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        //   onPressed: () {
                        //     // Navigate to a detailed likes page (optional)
                        //   },
                        // ),
                      ],
                    ),
                  ),

                  //////////////////////////////////////
                  // Horizontal ListView for Profiles //
                  //////////////////////////////////////

                  SizedBox(
                    height: 120, // Adjust height as needed
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: dummyLikes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final like = dummyLikes[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedReceiverId = like['userId'];
                              inChat = true;
                            });
                          },
                          child: Container(
                            width: 90, // Fixed width for each profile card
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(like['profileImage']),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  like['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),                
              
                  SizedBox(height: 15),
              
                  //////////////////////
                  // Messages Section //
                  //////////////////////
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.black), bottom: BorderSide(color: Colors.black))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15, top: 15, bottom: 15),
                            child: Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              
                  //////////////////////////
                  // Active Conversations //
                  //////////////////////////

                  Expanded(
                    child: Scrollbar(
                      controller: _messagesScrollController,
                      thumbVisibility: true, // Always show scrollbar
                      interactive: true,
                      child: ListView.builder(
                        controller: _messagesScrollController,
                        itemCount: messageCount, 
                        itemBuilder: (BuildContext context, int index) {
                          final like = dummyLikes[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black))
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(like['profileImage']),
                              ),
                              title: Text(like['name']),
                              subtitle: Text('hello this is the latest message'),
                              onTap: () {
                                setState(() {
                                  selectedReceiverId = 'user$index';
                                  inChat = true;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ]
              ),
            ),
            
            if (inChat) 
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [

                  ////////////////////////
                  // In chat back arrow //
                  ////////////////////////
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            inChat = false;
                          });
                        },
                        icon: (Icon(Icons.arrow_back, color: Colors.white)),
                      ),
                    ]
                  ),
                  
                  //////////////////////////////
                  // Profile picture and name //
                  //////////////////////////////
                  
                  Positioned(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            //backgroundImage: NetworkImage(like['profileImage']),
                          ),
                          SizedBox(height: 15),
                          Container(
                            child: Text('Name Lastname')
                          ),
                        ]
                      ),
                    )
                  ),

                  /////////////////////////
                  // Message Text Editor //
                  /////////////////////////
                  
                  Positioned(
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 30,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            fillColor: Color(0x50FFFFFF),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            suffixIcon: IconButton(
                              onPressed: _sendMessage,
                              icon: Icon(Icons.send, color: Colors.black),
                              highlightColor: Color(0x20FFFFFF),
                            ),
                          ),
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (value) => _sendMessage(),
                          onTap: () => _focusNode.requestFocus(),
                          onTapOutside: (_) {
                            _focusNode.unfocus();
                          }
                        ),
                      ),
                    ),
                  ),
                ]
              ),
            )
          ],
        ),
      ),
    );
  }
}