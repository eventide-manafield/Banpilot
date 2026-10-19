# Eventide's Banpilot

> 어째서.
>
> 어째서 오른쪽 아래에, 가장 중요한 지점에 코파일럿 키를 박아두었는가.
>
> 용서할 수 없다.

**내 키보드에 네 자리는 없다.**

Copilot 키를 눌렀을 때 창을 열지 않고 바로 종료하는 작은 Windows 앱입니다.
Windows의 Copilot 키 사용자 지정에서 **Eventide's Banpilot**을 실행 대상으로 선택합니다.

현재 버전은 **0.1.0: 아무것도 하지 않고 종료하기**입니다. RCtrl/RAlt 변환은 포함하지 않습니다.

## 동작

- 실행 코드는 `return 0;`입니다. 창을 만들지 않고 즉시 종료합니다.
- 시작 프로그램, 서비스, 상주 루프, 키 입력 후킹, 네트워크 통신이 없습니다.
- 키보드 드라이버, Secure Boot, 테스트 모드 설정을 변경하지 않습니다.
- 키 입력 자체를 삭제하거나 다른 키로 바꾸는 앱은 아닙니다. Windows가 호출할 앱을 바꾸는 방식입니다.
- Windows 설정에 따라 `Win+C`에도 같은 앱이 연결될 수 있습니다.

Windows 11 x64용 실험 프로젝트입니다. 짧게 누르기, 길게 누르기, 다른 키와 함께 누르기의 동작은 실제 PC에서 확인해야 합니다.

## 설치 및 선택

1. 빌드 출력 폴더의 `Install.cmd`를 실행합니다.
2. 로컬 테스트용 공개 인증서 `CN=Eventide Banpilot Test`를 `LocalMachine\TrustedPeople`에 등록합니다. 관리자 권한이 필요합니다.
3. Windows 설정의 **키보드의 Copilot 키 사용자 지정**에서 사용자 지정 앱을 선택합니다. Windows 버전에 따라 개인 설정 → 텍스트 입력 또는 Bluetooth 및 장치 → 키보드에 있습니다.
4. **Eventide's Banpilot**을 선택합니다.
5. Copilot 키를 짧게 누르거나 길게 눌러 창이 나타나지 않는지 확인합니다.

설치기는 앱과 인증서를 설치합니다. Copilot 키의 실행 대상은 Windows 설정에서 선택합니다. 앱 목록에 나타나지 않으면 설정 창을 다시 엽니다.

### 테스트 인증서

이 패키지는 자체 서명된 로컬 테스트 빌드입니다. 인증서 신뢰 등록은 앱을 종료한 후에도 남으며, 같은 인증서로 서명한 다른 코드의 신뢰 판단에도 영향을 줄 수 있습니다. 앱의 안전성을 외부 기관이 보증하는 것은 아닙니다.

배포 파일에는 공개 인증서 `.cer`만 포함합니다. 개인 키는 Windows의 현재 사용자 인증서 저장소에 비내보내기 키로 보관하며, Git 저장소나 배포 파일에 포함하지 않습니다. 소스와 빌드 스크립트를 먼저 확인하십시오.

## 빌드 및 확인

Windows PowerShell 5.1, Windows에 포함된 .NET Framework 컴파일러, Windows SDK `10.0.26100.0`의 x64 도구를 사용합니다.

```powershell
powershell.exe -NoProfile -File .\Build.ps1
```

`out` 아래 새 폴더에 MSIX, 공개 인증서, 설치기, 해시 및 인증서 지문이 담긴 `build.json`이 생성됩니다. 다른 PC에서 소스를 빌드하면 그 PC의 로컬 테스트 인증서를 생성합니다.

설치 전 패키지 확인:

```powershell
powershell.exe -NoProfile -File .\Install.ps1 -ReleaseDirectory (Get-Content .\out\latest.txt) -CheckOnly
```

설치 후 공급자 등록 및 앱 활성화 확인:

```powershell
powershell.exe -NoProfile -File .\Verify-Installed.ps1
```

자동 확인은 패키지 활성화와 프로세스 종료를 검사합니다. 실제 Copilot 키, 길게 누르기, 재로그인·재부팅 후 동작을 대신 검증하지 않습니다.

### 현재 검증 상태

2026-10-19 로컬 Windows 11 25H2 x64 PC에서 다음을 확인했습니다.

- MSIX 빌드·서명, 테스트 인증서 신뢰 등록, 앱 설치 성공
- Copilot 키 공급자 등록과 Windows 설정 앱 선택 목록 표시 확인
- 패키지 활성화 5회 모두 종료 및 전경 창 유지 확인, 상주 프로세스 없음
- Windows 설정에서 Banpilot 선택 후 저장된 Copilot 키 연결 값 확인
- 사용자 실사용에서 무동작으로 보인다는 초기 피드백을 받음. 음소거 상태였으므로 음성 동작까지 검증된 것으로 간주하지 않음
- 실제 키의 짧게·길게 누르기, 다른 키와의 조합, 재로그인·재부팅 후 검증은 아직 완료하지 않음

## 제거 및 복구

1. Windows 설정에서 Copilot 키의 실행 대상을 원하는 앱으로 다시 선택합니다.
2. 설치된 앱에서 **Eventide's Banpilot**을 제거합니다.
3. 이 테스트 인증서를 더 이상 사용하지 않으면 `certlm.msc`의 **신뢰할 수 있는 사람 → 인증서**에서 `build.json`의 지문과 정확히 일치하는 인증서를 제거합니다. 다른 앱에서도 같은 인증서를 사용하는지 먼저 확인하십시오.

## 참고

- [Microsoft Copilot hardware key providers](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/microsoft-copilot-key-provider)
- [MSIX 자체 서명 인증서](https://learn.microsoft.com/en-us/windows/msix/package/create-certificate-package-signing)
