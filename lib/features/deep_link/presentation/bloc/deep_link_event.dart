part of 'deep_link_bloc.dart';

abstract class DeepLinkEvent extends Equatable {
  const DeepLinkEvent();

  @override
  List<Object?> get props => [];
}

class DeepLinkStarted extends DeepLinkEvent {
  final List<String> args;
  const DeepLinkStarted({this.args = const []});

  @override
  List<Object?> get props => [args];
}

class DeepLinkReceived extends DeepLinkEvent {
  final Uri uri;

  const DeepLinkReceived(this.uri);

  @override
  List<Object?> get props => [uri];
}

class DeepLinkManualEntry extends DeepLinkEvent {
  final String token;

  const DeepLinkManualEntry(this.token);

  @override
  List<Object?> get props => [token];
}
