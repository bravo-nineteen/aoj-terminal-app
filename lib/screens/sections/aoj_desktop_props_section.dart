part of '../aoj_desktop.dart';

extension _AojDesktopPropsSection on _AOJDesktopState {
  Widget _buildPropsSection(DesktopWindowData window) {
    return PropsPanel(
      accent: window.accent,
      event: activeEvent,
      propIpController: propIpController,
      showPropControlPage: showPropControlPage,
      propControlStatus: propControlStatus,
      onOpenPropControlPage: _openPropControlPage,
      onClosePropControlPage: _closePropControlPage,
      normalizedPropUrl: _normalizedPropUrl,
      onPageStarted: () {
        _refresh(() {
          propControlStatus = 'CONNECTING TO PROP';
        });
      },
      onPageFinished: () {
        _refresh(() {
          propControlStatus = 'PROP CONSOLE LINKED';
        });
      },
      onWebError: (message) {
        _refresh(() {
          propControlStatus = message;
        });
      },
    );
  }
}
