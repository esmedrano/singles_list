import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      // Add your send logic here (e.g., update ListView)
      print('Sending: ${_controller.text}');
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: 2,  // In my case calculated from the screen height  
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Color(0x50FFFFFF),
                          borderRadius: BorderRadius.circular(8.0)
                        ),
              
                        child: Text('Hello'),
                      ),
                    );
                  }
              
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Color(0x50FFFFFF),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
              
                      child: Text('Hi!'), 
        
                    ),
                  );
                },
              ),
            ),
          
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    ),
                  ),
                ],
              ),
            ),
        
            // // Send Button
            // Container(
            //   alignment: Alignment.bottomRight,  // Does work because
            //   child: IconButton(
            //     // alignment: Alignment.bottomRight, doesn't work because it is in a column so centered overrides it 
            //     onPressed: (() {
              
            //     }),
              
            //     icon: Icon(Icons.send),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}