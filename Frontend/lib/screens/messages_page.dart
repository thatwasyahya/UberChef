// lib/screens/messages_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final List<MessageConversation> _conversations = _generateMockConversations();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Rechercher des conversations
            },
          ),
        ],
      ),
      body: _conversations.isEmpty
          ? _buildEmptyState()
          : _buildConversationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Aucun message',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Vous n\'avez pas encore de conversations avec des restaurants',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(MessageConversation conversation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: NetworkImage(conversation.restaurantImageUrl),
            ),
            if (conversation.hasUnreadMessage)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                conversation.restaurantName,
                style: GoogleFonts.montserrat(
                  fontWeight: conversation.hasUnreadMessage ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTime(conversation.lastMessageTime),
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: conversation.hasUnreadMessage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            conversation.lastMessage,
            style: GoogleFonts.montserrat(
              fontWeight: conversation.hasUnreadMessage ? FontWeight.w500 : FontWeight.normal,
              fontSize: 14,
              color: conversation.hasUnreadMessage ? Colors.black87 : Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () {
          // Naviguer vers la conversation détaillée
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Conversation avec ${conversation.restaurantName}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}

class MessageConversation {
  final String id;
  final String restaurantName;
  final String restaurantImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnreadMessage;

  MessageConversation({
    required this.id,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.hasUnreadMessage = false,
  });
}

List<MessageConversation> _generateMockConversations() {
  return [
    MessageConversation(
      id: '1',
      restaurantName: 'La Belle Assiette',
      restaurantImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8cmVzdGF1cmFudHxlbnwwfHwwfHw%3D&w=1000&q=80',
      lastMessage: 'Votre réservation a été confirmée pour ce soir à 20h. Au plaisir de vous accueillir !',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      hasUnreadMessage: true,
    ),
    MessageConversation(
      id: '2',
      restaurantName: 'Pizzeria Napoli',
      restaurantImageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1074&q=80',
      lastMessage: 'Merci pour votre commande ! Votre pizza sera prête dans 15 minutes.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      hasUnreadMessage: true,
    ),
    MessageConversation(
      id: '3',
      restaurantName: 'Burger House',
      restaurantImageUrl: 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MTB8fGJ1cmdlciUyMHJlc3RhdXJhbnR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60',
      lastMessage: 'Nous avons une offre spéciale ce week-end : -30% sur nos menus burgers premium !',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MessageConversation(
      id: '4',
      restaurantName: 'Green Garden',
      restaurantImageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NXx8dmVnZXRhcmlhbiUyMHJlc3RhdXJhbnR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60',
      lastMessage: 'Avez-vous apprécié nos nouveaux plats végétariens ? Nous aimerions avoir votre avis.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MessageConversation(
      id: '5',
      restaurantName: 'Bistro Parisien',
      restaurantImageUrl: 'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80',
      lastMessage: 'Bonjour ! Notre chef a préparé un menu spécial pour la Saint-Valentin. Souhaitez-vous réserver ?',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MessageConversation(
      id: '6',
      restaurantName: 'Le Gourmet',
      restaurantImageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8ZmluZSUyMGRpbmluZ3xlbnwwfHwwfHw%3D&auto=format&fit=crop&w=500&q=60',
      lastMessage: 'Nous avons le plaisir de vous inviter à notre soirée dégustation de vins ce vendredi.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 7)),
    ),
    MessageConversation(
      id: '7',
      restaurantName: 'Tokyo Sushi',
      restaurantImageUrl: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NXx8c3VzaGklMjByZXN0YXVyYW50fGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60',
      lastMessage: 'Voici la liste des nouveaux plats disponibles à partir de la semaine prochaine.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];
}