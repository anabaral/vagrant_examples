# Vagrant와 Virtualbox 를 이용하여 PC에서 kubernetes 를 설치

조건
1) PC의 메모리가 12GB 정도 이상은 되어야 합니다. (잘 조정하면 8GB로도 될 지 모르지만, 저는 실패 했었음)
2) PC는 Windows 7 이상이라고 가정합니다. Linux 도 가능하겠지만 저는 Windows 10 에서 진행했습니다.
3) VirtualBox 가능하면 최신판을 설치합니다. 제 경우는 6.1 버전을 설치했습니다.
4) 적절한 디렉터리에 Vagrant를 설치합니다. 제 경우는 2.2.7 버전을 설치했습니다.
5) Windows 10이라면 hyper-V 옵션을 꺼둡니다. 관련해서 "virtualbox hyper-v 충돌" 같은 검색어로 검색해 보세요.
   일단 실행해 보고 실패하면 실패 메시지를 보고 대응하셔도 됩니다.

실행
1) 적절한 디렉터리에서 파일들을 받아둡니다.
   <pre><code>git clone https://github.com/anabaral/vagrant_examples/tree/master/vbox_kube
   </code></pre>
2) Vagrant 를 실행하면 VM을 세 개 띄우고 Kubernetes를 설치합니다. 
   <pre><code>vagrant up 
   </code></pre>
   하나가 Master 노드, 다른 두 개가 Worker 노드로 셋업 됩니다.
3) Master 노드에 접속하면 kubectl 등 명령어를 쓸 수 있습니다.
   여기에 dashboard-2.0.0-rc5.sh 를 가져와서 실행하면 kubernetes 대시보드가 설치됩니다.
   <pre><code> sh dashboard-2.0.0-rc5.sh </code></pre>
   실행 마지막에 다음과 같은 안내 메시지가 나올 텐데 이를 따르면 접속 및 사용할 수 있습니다.
   <pre><code>### 1) Edit your hosts file to add this host to be dashboard.k8s.com"
   ### 2) Access dashboard by https://dashboard.k8s.com:32443/"
   ### 3) Choose option 'config' and upload the config file generated."
   </code></pre>
   - host ip 는 virtualbox VM 을 PC에서 접속하기 위한 ip 입니다. 
     NAT 설정 같은 별도의 네트워크 설정이 필요할 겁니다. 이것은 virtualbox 에 대한 이해와 관련되어 여기서는 설명을 생략합니다..
   - kubernetes dashboard 는 인증을 아예 하지 않는 사용도 가능한데 이는 여기서 설명하지 않겠습니다. (검색해 보면 나와요)
   - 관리자로서 인증하기 위한 인증파일(config 파일)은 Vagrantfile이 위치한 디렉터리에 생성됩니다.
     이 디렉터리는 모든 VM이 /vagrant 위치로 공유하고 있는 접근 가능한 디렉터리이기도 합니다.
     config 파일을 대시보드 로그인에 업로드하여 인증을 합니다.
4) 메트릭서버를 설치합니다.
   <pre><code>sh install-metrics-server.sh </code></pre>
   이것을 설치하면 kubernetes 자체 메트릭 수집이 이루어지며,
   - 대시보드에서 CPU 등의 상태를 볼 수 있고
   - kubectl top 명령 등으로 상태를 확인하는 것이 가능해집니다.
   - 당장 확인할 수는 없지만, pod autoscale 에 사용되는 메트릭도 이것이 수집합니다.
5) 위의 설명이 불충분할 수 있습니다. 
   혹은 환경의 차이로 잘 안될 수도 있습니다.
   이슈를 제기해 주세요.

추가
- 다음의 오류가 나면서 virtualbox 를 사용할 수 없는 것을 발견했습니다:
  <pre><code>Stderr: VBoxManage.exe: error: The virtual machine 'k8s-head' has terminated unexpectedly during startup with exit code 1 (0x1).  More details may be available in 'C:\Users\Administrator\VirtualBox VMs\Ballerina Development\k8s-head\Logs\VBoxHardening.log'
  VBoxManage.exe: error: Details: code E_FAIL (0x80004005), component MachineWrap, interface IMachine</code></pre>
  이 에러에 대한 대처 방법은 두 가지가 있습니다. 경우에 따라서는 둘 다 해야 할 수 있습니다.
  1) vagrant를 실행하는 커맨드 창이 관리자 권한으로 실행되고 있어야 합니다.
  2) 놀랍게도 Windows 10 에서 Citrix 계열의 VDI 를 사용할 때 나기도 합니다. 이럴 경우 나다가 안 나다가 해서 명확한 원인을 찾지 못했는데
     회사용 VDI를 닫거나 최소화 하니 해제되는 걸 발견했습니다. 해결 방법은 Windows 10의 경우 VDI 와 vagrant 실행 데스크톱(Desktop)을 
     분리하기만 해도 괜찮아집니다. (윈도우 키 + TAB 키 같이 눌러 보면 무슨 의미인지 아실 듯)
     회사용 VDI의 경우 화면복제금지 같은 다양한 보안 기능을 기동하는데 이것이 Virtualbox와 충돌하나 봅니다. 
- 그 외에, 서비스들이 간혹 32443 포트 (대시보드 사용) 를 랜덤 점유해서 문제가 되는 경우가 있습니다. 
  보통은 해당 프로세스를 죽이면 서비스가 다시 뜨면서 다른 포트를 사용하므로 해결됩니다.
  <pre><code>C:\> taskkill /f /im complicting_process.exe </code></pre>
