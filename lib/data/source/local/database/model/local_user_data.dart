import 'package:objectbox/objectbox.dart';

import 'base_local_data.dart';
import 'local_image_url_data.dart';

@Entity()
class LocalUserData extends BaseLocalData {
  @Id(assignable: true)
  int id;
  String nickname;
  String email;
  final avatar = ToOne<LocalImageUrlData>();

  LocalUserData(
      {required this.id, required this.nickname, required this.email});

  @override
  List<Object?> get props => [id, nickname, email, avatar];
}
