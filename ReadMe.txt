### 25/02/20
	1. Backup Page
		- USB 데이터 복사 기능 구현
			: 복사 범위 선택을 해야 복사 시작
			: USB 데이터 복사시 HotPADData_yyyyMM 폴더 아래 저장
			: 만약 동일한 폴더가 있으면 폴더를 삭제 후 다시 폴더 생성
			: Isolate를 사용하여 복사 기능 구현
			: .db To .csv로 데이터를 변환하는데 100라인씩 변환하여 저장
			: 복사되는 동안 Indicator로 동작 중임을 알려줌
			: Indicator가 활성화 중인 상태에서는 다른 버튼 입력이 안됨
			: 데이터 복사 중에 Alarm/Graph/Log 데이터 저장은 안됨
		
### 25/02/17
	1. Backup Page
		- 파일 복사 시작 - 마지막 항목 선택 수정
			--> DropDownMenu의 TextEditingController를 추가하여 item항목을 잘못 선택한 경우 수정할 수 있도록 함.
			
		- USB 데이터 삭제 제거
			--> USB 데이터를 삭제할 필요성이 없는 것 같아서 삭제
			
		- 내부 데이터 삭제 추가
			--> 내부 데이터가 많아 삭제해야 하는 경우 사용
			--> 삭제 범위를 설정하여 삭제
			--> 삭제시 추가로 확인을 함
			--> 삭제 후 내부용량 재확인

### 25/02/14
	1. Graph 파일 검색 후 그래프 그리기
		- Graph 파일 검색하여 찾은 파일을 선택하면,
		  상단에 파일명을 표시하면서 해당 파일의 데이터를 그래프로 표시
		- 실시간 데이터는 계속 저장되고, 현재 그래프가 라이브 상태를 log 파일에 표시

	2. Alarm 파일 구조
		- id, channel, hotpad, code, descriptions, dateTime
		- 장비에서 언어 설정에 따라 표기하기 위하여 code를 저장
		
	3. Graph 파일 구조
		- time, ststus(HeatingStatus), rtd
		
	4. Log 파일 구조
		- 추후 문제가 발생할 때 검토하기 위함
		- time, live, mode(PU15/PU45), heatingStatus, rtd, crnt, cmd, ohm, acVtg, dcVtg, dcCrnt, intTemp
		
	5. backup page 기능 구현 중
		- 최대 선택 버튼 동작 구현
		- 복사 시작-마지막 선택 dropdownMenu 리스트 구현 중
			--> 항목 리스트 구현
			--> 선택 항목이 잘못된 경우 수정하는 부분 구현 중
	
### 25/02/13
	1. 파일 구조 변경
		- HotPADData --- Alarm --- 202502
					  |			|
					  |			-- 202503
					  -- Graph --- 202502
					  |			|
					  |			-- 202503
					  -- Log   --- 202502
					  |			|
					  |			-- 202503
					  -- ScreenShots --- 202502
					  				  |
									  -- 202503
		- 각 폴더의 서브 폴더는 월단위로 생성됩니다
		
	2. Graph 파일 검색 기능 추가
		- Search와 Live 버튼 추가


### 25/02/12
	1. Graph 파일 저장 기능 추가
	  - 그래프 그려지는 주가(10초) 간격으로 데이터 저장
	  - SQLite 형식으로 파일 저장
	  - updateChartData() 함수에 추가
	  
	2. Log 파일 저장 기능 추가
	  - onDataReceived() 함수에서 수신된 데이터를 10회 저장 후 파일에 저장
	  - SQLite 형식으로 파일 저장

### 25/02/11
	1. 시작/예열 버튼 입력시 PU15/PU45 모드에 따라 잔여시간 및 동작 상태 설정
	2. PU15, PU45 시간에 따라 동작 상태 변경
	3. 내부 용량 확인 함수를 hotpad_ctrl.dart로 옮김
		- 1분 간격으로 용량 check
		
### 25/02/10
	1. HotpadCtrl 클래스 추가
		- hotpad_ctrl.dart 파일 추가
		- 데이터 통합 관리 클래스
		- isolate를 사용하여 GUI와 구분
		- 현재 Serial 통신 및 현재 시간 관리
		- 추가적으로 PID 및 Hotpad 제어 부분 구현 예정
	
	2. 기타 수정 사항
		- backup_page의 언어 변경에 따른 레이아웃 변동을 수정
		- 25/02/07 1항에 오류 부분을 수정
			--> main.dart에 현재 시간을 표시하기 위해 사용한 타이머로 인한 데이터 2번 알림이 발생하는 것을 
			    HotpadCtrl 클래스 적용(현재 시간을 본 클래스로 이동)으로 notifyListeners()를 사용하여
				데이터 변경 사항을 전달하는 것으로 변경
		
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
		

		