//Functional script to launch a Kerbal X

// Heavily plagirised from CheersKevin's excellent youtube tutorial 
// https://www.youtube.com/watch?v=1yS3BUxQ-VQ&list=RDCMUC-Fn23Q_91AEQHr2uNMd2VQ&index=2


function main {
  doLaunch().
  doAscent().
  until apoapsis >100000 {
    doAutoStage().
  }
  doShutdown().
  executeManeuver(time:seconds + 210, 0, 0, 480).
  print "Orbital insertion complete".
}

function doLaunch {
  print "Launching".
  lock throttle to 1.
  doSafeStage().
}

function doAscent {
  lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
  set targetDirection to 90.
  lock steering to heading(targetDirection, targetPitch).
}

function doAutoStage {
  if not(defined oldThrust) {
    declare global oldThrust to ship:availablethrust.
  }
  if ship:availableThrust < (oldThrust - 10) {
    doSafeStage(). wait 1.
    declare global oldThrust to ship:availablethrust.
  }
}

function doShutdown {
  lock throttle to 0.
  lock steering to prograde.
  print "Engine shutdown".
}

function doSafeStage {
  wait until stage:ready.
  stage.
  print "Staging".
}

function executeManeuver {
  parameter utime, radial, normal, prog.
  print "Planning maneuver".
  local mnv is node(utime, radial, normal, prog).
  add mnv.
  local startTime is calculateStartTime(mnv).
  wait until time:seconds > startTime - 20.
  lock steering to mnv:burnvector.
  print "Locking steering to burn vector".
  wait until time:seconds > startTime.
  lock throttle to 1.
  print "Burning".
  wait until isManeuverComplete(mnv).
  remove mnv.
}

function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - (maneuverBurnTime(mnv) / 2).
}

function maneuverBurnTime {
  parameter mnv.

  local dV is mnv:deltav:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:maxThrust / ship:maxThrust)).
    }
  }

  local massFinal is ship:mass / constant():e^(dV /(isp * g0)).
  local massFlowRate is ship:maxthrust / (isp * g0).
  local t is (ship:mass - massFinal)/massFlowRate.

  print "Burntime is " + t + "s".
  return t.
// return mnv:deltav:mag/(ship:maxthrust/ship:mass). // simplified calculation (works)
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return True.
  }
}

// Initiate launch
main().