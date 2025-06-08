import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 1)
class UserSettings extends HiveObject {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String currency;
  
  @HiveField(2)  
  String theme;
  
  UserSettings({
    this.name = '',
    this.currency = '₹',
    this.theme = 'system',
  });
}
