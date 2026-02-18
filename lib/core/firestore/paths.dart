import 'collections.dart' as collections;

String userDoc(String uid) => '${collections.users}/$uid';

String userAppointmentsCol(String uid) =>
    '${collections.users}/$uid/${collections.appointments}';

String userMedicationsCol(String uid) =>
    '${collections.users}/$uid/${collections.medications}';

String medicationIntakesCol(String uid, String medicationId) =>
    '${collections.users}/$uid/${collections.medications}/$medicationId/${collections.intakes}';

String userChatsCol(String uid) =>
    '${collections.users}/$uid/${collections.chats}';

String chatMessagesCol(String uid, String chatId) =>
    '${collections.users}/$uid/${collections.chats}/$chatId/${collections.messages}';

String userSettingsDoc(String uid) =>
    '${collections.users}/$uid/${collections.settings}/main';
