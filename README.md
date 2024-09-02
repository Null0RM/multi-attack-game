# multi-attack-game

![main image](images/main.png)

돈이 곧 힘이다! WEB3기반 P2P 전투게임에 오신 것을 환영합니다!

상대를 지목하여 p2p 전장에 불러올 수 있고, 직업을 선택하여 상대와 전쟁을 할 수 있습니다.   
공격할 수 있는 횟수는 가진 공격포인트를 모두 소진할 때 까지이며, 한 번에 여러번 공격 또한 가능합니다.    
전투에서 이기게 된다면, 이에 대한 보상으로 전투에서 상대를 굴복시켰다는 증표를 NFT로 받게 됩니다.

__무운을 빕니다!__   

| type | Todo | Done | 
| ----- | ------ | ------- |
| 코드 패턴 #1 | State Machine | .. |
| 코드 패턴 #2 | Multicall Pattern | .. |
| 코드 패턴 #3 | Checks Effects Interactions | .. |
| 코드 패턴 #4 | Pull over Push | .. |
| 코드 패턴 #5 | Emergency Stop | .. |
| 도전 과제 #1 | 추가 패턴 | .. |
| 도전 과제 #2 | 토크노믹스 | .. |
| 도전 과제 #3 | 취약점 | .. |
| 도전 과제 #4 | 성능/가스최적화 | .. |

### Upgradable    
- UUPSUpgradable pattern   
- onlyOwner

### 게임 카운터    
- 이더 <--> war token 교환   
- 상대를 초대: "You Invited to P2P game" by msg.data & send token
- 권한 delegation (가진 토큰을 모두 보내줄 수 있어야 함)
- 게임중에도 토큰 구매 가능 (ETH -> war token)
- 게임 인스턴스 생성
- 만들어진 게임 인스턴스를 이벤트로그로 띄워줌. & return해줌

### 게임 인스턴스 생성
#### phase1
- 상대 기다리기
- 전투 준비

#### phase2
- 얼만큼의 돈을 배팅할지 결정
- 상대가 얼마나 걸었는지 보고 배팅을 추가할 수 있음
- 공격, 방어에 배팅한 돈을 분배
- 미리 아이템도 구매 가능 (힐링 포션, 공격력 업그레이드 포션)

#### phase3
- 직업 선택
    * Warrior : 검사 (적당한 공격력, 강한 방어, 적당한 공격 코스트)
    * Archer : 궁수 (약한 공격력, 약한 방어력, 낮은 공격 코스트)
    * Mage : 마법사 (강한 공격력, 약한 방어력, 조금 높은 공격 코스트, 힐 능력 존재)
    * Druid : 드루이드 (강한 공격력, 강한 방어력, 높은 공격 코스트, 힐 능력 존재)

#### phase4
- 전투 페이즈    
    * war token을 지불하고, 그만큼의 공격 수행 가능   
    * 빠른 공격을 위해 multicall수행 가능        
    * 체력이 0이 되면 더이상 공격을 수행 불가 (underflow 체크)     
- Warrior     
	* Berserk Slash: 피해량 40, MP 소모 20     
	* Whirlwind: 피해량 30(모든 적에게), MP 소모 30     
	* Shield Bash: 피해량 15, MP 소모 15 (추가 효과: 1초 기절)     
- Archer     
	* Piercing Arrow: 피해량 50, MP 소모 25     
	* Multi-Shot: 피해량 25(각 화살당), MP 소모 35     
	* Explosive Trap: 피해량 60, MP 소모 20     
- Mage     
	* Fireball: 피해량 70, MP 소모 30 (추가 화상 효과)     
	* Lightning Bolt: 피해량 60, MP 소모 25     
	* Ice Spike: 피해량 40, MP 소모 20 (추가 둔화 효과)     
- Druid     
	* Nature’s Wrath: 피해량 45, MP 소모 20     
	* Healing Touch: 치유량 50, MP 소모 25     
	* Thorn Armor: 피해량 10(반격 시), MP 소모 15 (10초 지속)     

### phase5
- 보상 페이즈
    * 패자가 스킬을 쓰는 데 사용했던 war token이 승자에게 귀속
    * 이중 10%의 war token이 수수료로 납부
    * 이에 대해 승리의 증표 & 조롱이 가능한 NFT발급 가능

### 인스턴스 정보
- RPC: upside:center39383817284134737847833@rpc.exploit101.com

# directory 

## ERC20

## ERC721

## IMultiAttack

## MultiAttackV1

## 