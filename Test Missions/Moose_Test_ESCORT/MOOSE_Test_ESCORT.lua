Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Spawn" )
Include.File( "Escort" )



do
  local function EventAliveHelicopter( Client )
    local EscortGroupHeli1 = SpawnEscortHeli:ReSpawn(1)
    local EscortHeli1 = ESCORT:New( Client, EscortGroupHeli1, "Escort Alpha" )
    local EscortGroupPlane1 = SpawnEscortPlane:ReSpawn(1)
    local EscortPlane1 = ESCORT:New( Client, EscortGroupPlane1, "Escort Test Plane" )
    local EscortGroupGround1 = SpawnEscortGround:ReSpawn(1)
    local EscortGround1 = ESCORT:New( Client, EscortGroupGround1, "Test Ground" )
  end
  
  local function EventAlivePlane( Client )
    local EscortGroupPlane2 = SpawnEscortPlane:ReSpawn(1)
    local EscortPlane2 = ESCORT:New( Client, EscortGroupPlane2, "Escort Test Plane" )
    
    local EscortGroupGround2 = SpawnEscortGround:ReSpawn(1)
    local EscortGround2 = ESCORT:New( Client, EscortGroupGround2, "Test Ground" )

    local EscortGroupShip2 = SpawnEscortShip:ReSpawn(1)
    local EscortShip2 = ESCORT:New( Client, EscortGroupShip2, "Test Ship" )
  end

  SpawnEscortHeli = SPAWN:New( "Escort Helicopter" )
  SpawnEscortPlane = SPAWN:New( "Escort Plane" )
  SpawnEscortGround = SPAWN:New( "Escort Ground" )
  SpawnEscortShip = SPAWN:New( "Escort Ship" )

  EscortClientHeli = CLIENT:New( "Lead Helicopter", "Fly around and observe the behaviour of the escort helicopter" ):Alive( EventAliveHelicopter )  
  EscortClientPlane = CLIENT:New( "Lead Plane", "Fly around and observe the behaviour of the escort airplane. Select Navigate->Joun-Up and airplane should follow you. Change speed and directions." )
                                  :Alive( EventAlivePlane )                                    

end

-- MISSION SCHEDULER STARTUP
MISSIONSCHEDULER.Start()
MISSIONSCHEDULER.ReportMenu()
MISSIONSCHEDULER.ReportMissionsHide()

env.info( "Test Mission loaded" )