import 'package:chatlynx/modelos/user_profile.dart';
import 'package:flutter/material.dart';

class ChatTile extends StatelessWidget {
  final UserProfile userProfile;
  final Function onTap;
  final String lastMessage;

  const ChatTile(
      {super.key,
      required this.userProfile,
      required this.onTap,
      required this.lastMessage});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTap();
      },
      dense: false,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          userProfile.pfpURL!,
        ),
      ),
      title: Text(
        userProfile.name!,
      ),
      subtitle: Text(
        userProfile.getMessageDisplay(lastMessage),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
