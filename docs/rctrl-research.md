# 다음 버전 연구: Copilot 키를 RCtrl로 사용하기

상태: 설계 조사. 키 변환 코드는 아직 구현하지 않았습니다.

기준 버전은 `main`의 Banpilot 0.1.0입니다. 이 연구 브랜치에서도 기존 앱의 무동작 기능과 패키지 버전은 유지합니다. 연구만으로 설치된 앱, 시작 프로그램, 드라이버, 인증서 신뢰 설정을 변경하지 않습니다.

## 목표

Copilot 키를 누르고 있는 동안 RCtrl이 눌린 상태를 유지하고, 키를 떼면 RCtrl을 해제하는 동작을 검토합니다. `Copilot+C`가 `RCtrl+C`로 동작해야 합니다. 한 번의 RCtrl 누름/해제 입력을 생성하는 것은 이 목표를 충족하지 않습니다.

RCtrl을 우선 검토하고 RAlt는 후속 후보로 둡니다. RAlt는 사용 중인 키보드 레이아웃 및 입력기의 동작을 추가 검증해야 합니다. 설정 화면을 먼저 만들기보다 실제 입력 처리가 가능한지부터 확인합니다.

## 현재 확인한 근거

- 현재 앱은 Windows의 `com.microsoft.windows.copilotkeyprovider` 확장에 등록한 실행 대상입니다. 이 확장 자체는 물리 키의 누름/해제를 전달하는 인터페이스를 문서화하지 않습니다.
- 2026-10-19 현재 PC에서 관찰한 순서는 `LWin DOWN → LShift DOWN → F23 DOWN`, 해제 순서는 `F23 UP → LShift UP → LWin UP`입니다.
- 약 1.19초 누름에서 F23 DOWN이 21회 관찰됐고 LWin·LShift DOWN도 반복됐습니다. 최초 입력만 처리해서는 충분하지 않습니다.
- 이 관찰은 사용자 공간 키보드 훅의 결과입니다. 모든 기기·키보드·펌웨어가 같은 입력을 보낸다고 가정하지 않습니다. 물리 장치별 식별은 이 기록에 포함되지 않습니다.
- 이 PC의 Windows 설정에서 직접 확인한 선택지는 검색, Copilot, 앱 열기였습니다. RCtrl을 제공하는 Windows 버전 또는 제조사 설정이 있다면 그 경로를 별도로 확인합니다.

## 구현 후보와 제약

| 후보 | 판단 | 다음 확인 |
| --- | --- | --- |
| 기존 앱 실행 후 RCtrl 입력 합성 | 누르고 있기와 해제를 보장하지 못하므로 단독 해법으로 채택하지 않음 | 앱 활성화 시점과 물리 키 이벤트는 서로 다름 |
| 사용자 공간의 상주 입력 처리 | 첫 구현 실험 후보. 상주 프로그램을 허용한다는 제품 결정이 필요함 | 일반 Win·Shift와 Copilot 입력 구분, 원래 입력 차단, 해제 보장, 관리자 앱과의 동작 |
| 키보드 필터 드라이버 | 후순위 | 드라이버 서명·배포, 장치별 입력 형태, 부팅·절전·분리 및 복구 검증 |
| Windows/제조사의 기본 키 변환 | 지원 환경에서는 우선 검토 | 현재 빌드와 키보드에서 지원되는지 확인 |

`SendInput`은 이미 눌린 키 상태를 초기화하지 않으며, 현재 눌린 Win·Shift가 합성 입력에 영향을 줄 수 있습니다. 또한 더 높은 무결성 수준의 앱으로 입력을 주입하는 데 제한이 있습니다. 키 변환이 모든 앱에서 동작한다고 약속하지 않습니다.

일반 키보드의 Win·Shift 입력을 일괄 삭제하거나 짧은 시간 간격만으로 Copilot 입력이라고 확정하면 정상 단축키를 훼손할 수 있습니다. 타이밍 추정만으로 범용 지원을 선언하지 않습니다.

## 첫 실험 순서

1. 자동 종료되는 관찰 도구로 짧게 누름, 길게 누름, 연타, Win·Shift를 먼저 누른 경우의 입력 순서를 비교합니다. 일반 문자 내용이나 전체 타이핑을 저장하지 않습니다.
2. 익명화한 제한된 이벤트 시퀀스로 상태 전이를 설계합니다. 일반 Win·Shift를 보존할 수 없으면 해당 접근의 한계로 기록합니다.
3. RCtrl 누름·반복·해제 처리를 별도 실험 프로그램으로 구현합니다. 자동 시작이나 드라이버 설치를 넣지 않고 명시적으로 실행·종료합니다.
4. 아래 실기 기준을 통과한 뒤에만 사용자용 선택 화면과 패키지 통합을 검토합니다.

## 통과 기준

- 짧게 누르기, 길게 누르기, 연타에서 Copilot 창이 열리지 않는다.
- 누르는 동안 `RCtrl+C`, `RCtrl+V`, `RCtrl+A`가 동작하고, 해제 후 Ctrl 상태가 남지 않는다.
- 원래 Win·Shift·Ctrl 및 한영 전환, 다른 키보드의 입력이 정상이다.
- Win 또는 Shift를 먼저 누른 상태에서도 오인식이나 키 고착이 없다.
- 일반 앱과 관리자 권한 앱의 결과를 구분해 기록한다.
- 프로그램 정상 종료, 오류, 절전·복귀, 키보드 분리·재연결에 대한 복구 동작을 검증한다.
- 지원하지 못하는 환경은 명시하고, 현재의 무동작 모드로 복구할 수 있다.

## 공식 참고 문서

- [Copilot hardware key provider](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/microsoft-copilot-key-provider)
- [SendInput 및 기존 키 상태/UIPI 제약](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)
- [LowLevelKeyboardProc](https://learn.microsoft.com/en-us/windows/win32/winmsg/lowlevelkeyboardproc)
- [키보드 필터 드라이버 구조](https://learn.microsoft.com/en-us/previous-versions/windows/hardware/hid/keyboard-and-mouse-class-drivers)
