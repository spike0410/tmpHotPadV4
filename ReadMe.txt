### 25/02/07
	1. Graph 오류 수정
		- SerialCtrl 클래스가 ChangeNotifier를 상속하였고, onDataReceived()함수를 StreamSubscription로 콜백을 선언하였다.
		  onDataReceived()함수에서 notifyListeners()로 데이터 변경을 알리는데 
		  이 함수를 사용하면 serial Rx 데이터가 변경되었다고 2번 알림
		- 그래서 notifyListeners() 함수를 주석처리하였음.
		- 또한 Provider를 사용하여 SerialCtrl을 호출하는 부분을 모두 Consumer를 사용하였다.
		
	2. 데이터 파일
		- Alarm/Graph/Log를 SQLite 파일로 저장
		- Download/HotpadData/xxx 각 폴더에 파일을 생성
		- 모든 파일은 전원이 켜질 때 생성이되며
		  Alarm은 1 Day 단위로, Graph/Log는 초단위로 구분하여 생성됩니다.
	
### 25/02/06
	1. 인스턴트 메세지 수정
		- 시작/예열 버튼 동작에 대한 오류 내용을 출력됨
		- Serial 통신 오류에 대한 메세지 출력됨
		- 한글/영문 변환이 가능함
		
	2. Alarm Page
		- 인스턴트 메세지에서 출력된 내용을 표시
		- 시작/예열 버튼 동작에 대한 내용을 출력됨
		
	3. Graph 오류 수정 중
		- Serial 통신으로 sendData를 1초 간격으로 보내면 응답으로 수신데이터를 받음
		- 수신된 데이터를 그래프를 그리는데 그래프 데이터가 많이 쌓이면 시간 간격이 늘어지는 현상이 발생
		- 위 현상을 줄이기 위하여 isolate를 사용하여 Timer와 onDataReceived() 콜백함수를 GUI와 별개로 동작하여 확인 중
	
		
### 25/02/05
	1. showDialog 오류 수정
		- showDialog를 사용하는 password 입력/변경 다이얼로그에서 반복 호촐시 오류발생
		- Timer를 사용하여 일정시간 후 사라지게 하였고, 확인 및 닫기를 한 경우 Timer.clear하여
		  오류 발생을 제거
		  
	2. Graph X축 설정 변경
		- 그래프가 maximum에 다가오면 maximum을 확장하고, 보조선을 12칸으로 일정하게 유지
	
### 25/02/04
	1. Main Page 수정
		- body에 stack으로 사용하는 대신 pageView로 변경
			--> SetupPage를 이동시 TabBar를 index = 0으로 하기 위해서 초기화를 하기 위함
		- pageView는 비활성화된 페이지를 메모리에 유지하지 않기 때문에, 다시 활성화될 때 페이지가 다시 빌드된다.
		- 그래서 GraphPage는 비활성화 상태에서도 유지하기 위해서 AutomaticKeepAliveClientMixin를 사용하였다.
		
	2. Authentication Provider
		- Authentication Provider를 통하여 Password 활성화
		- Setup Page
			--> Setup Password 활성화
			--> Password : 0000
			
		- Control Page
			--> Control Password 활성화
			--> Password : 54321
			
	3. 비밀번호 변경
		- SystemTab은 SetupPage와 ControlPage에서 호출이 가능함
		- SystemTab(isAdmin: false) : SetupPage에서 호출
		- SystemTab(isAdmin: true) : ControlPage에서 호출
		- 위와 같이 구분하여 SystemTab의 비밀번호 변경이 구분되어 저장됨
			
### 25/02/03
	1. Log 폴더 구성
		- 안드로이드 Download의 HotpadData 폴더를 생성
		- 추후 Log관련 데이터는 HotpadData 폴더 내에 생성 예정
		- HotpadData하위 폴더에 Log, ScreenShots, Alarm 폴더를 생성
		
	2. Capture 구현
		- RepaintBoundary를 이용하여 Capture 영역 지정
		- HotpadData/ScreenShots 폴더에 yyyyMMdd_HHmmss.png 파일로 저장
		- 저장 관련(ok, fail, error등등) 메세지를 ScaffoldMessenger를 통해 화면 하단에 출력됨
	
### 25/01/31
	1. Serial 통신 테스트
		- Graph 페이지에 수신된 데이터를 그래프 그리기 연동 확인
		- x축의 maximum을 수신된 데이터와 시간을 비교하여 늘리는 것으로 하였음
		- 현재 테스트 모드로 초간격으로 되어 있음.
		
### 25/01/24
	1. Serial 통신
		- isolate를 사용하여 GUI와 분리하여 동작
		
	2. home page GUI 동작
		- 현재 온도, 목표 온도, PAD 전류, PAD 저항, 상태 표시 구현
		
### 25/01/23
	1. Serial 통신
		- Nucleo64-L412 보드를 이용하여 Serial 통신 테스트
			-- Test Source : D:\COMPANY\David\N996_STM\testHotpadSerial\
		- 1초 간격으로 PC -> MCU로 전송하면 PC <- MCU로 응답을 보내느 방식으로 테스트
		- 수신 데이터를 GUI에 표시 되도록 provider를 사용
		
### 25/01/22
	1. Serial 통신
		- Serial Port를 사용하여 통신을 구현하려고 하였으나, 안드로이드에서 Serial Port 구현이 쉽지 않고
		  pub.dev의 패키지 또한 구하기 어려움
		- USB to Serial를 이용한 usb_serial 패키지를 사용하여 Serial 통신을 구현
		
	2. Modbus RTU
		- Modbus RTU 역시 pub.dev에서 패키지를 구하기 어려움
		- Modbus RTU 라이브러리를 만드는 시간을 투자하는 대신 ascii 통신으로 구현할 예정.
	
	3. usb_serial 에러
		- version 0.5.2 사용시 빌드가 안되는 문제가 발생
		- 참고 URL : https://qiita.com/dekuo-03/items/ca6c613559fe283f2f02
		- 위 내용은 usb_serial 패키지 소스에서 수정을 해야함.
		- 패키지 소스 위치 : C:\Users\{user name}\AppData\Local\Pub\Cache\hosted\pub.dev\usb_serial-0.5.2
		

		