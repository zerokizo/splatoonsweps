
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(1, 0, 0)
SWEP.ADSOffset = Vector(-2, 0, 3)
SWEP.ShootSound = "SplatoonSWEPs.TriSlosher"
SWEP.Bodygroup = {[2] = 0}
SWEP.Special = "bubbler"
SWEP.Sub = "disruptor"
SWEP.Variations = {{
    Bodygroup = {[2] = 1},
    Customized = true,
    Special = "echolocator",
    Sub = "seeker",
    Suffix = "nouveau",
}}

ss.SetPrimary(SWEP, {
    mSwingLiftFrame = 12,
    mSwingRepeatFrame = 26,
    mFirstGroupBulletNum = 1,
    mFirstGroupBulletFirstInitSpeedBase = 13.3,
    mFirstGroupBulletFirstInitSpeedJumpingBase = 11.8,
    mFirstGroupBulletAfterInitSpeedOffset = 0,
    mFirstGroupBulletInitSpeedRandomZ = 0,
    mFirstGroupBulletInitSpeedRandomX = 0,
    mFirstGroupBulletInitVecYRate = 0.1,
    mFirstGroupBulletFirstDrawRadius = 14,
    mFirstGroupBulletAfterDrawRadiusOffset = 0,
    mFirstGroupBulletFirstPaintNearD = 50,
    mFirstGroupBulletFirstPaintNearR = 30,
    mFirstGroupBulletFirstPaintNearRate = 1,
    mFirstGroupBulletFirstPaintFarD = 120,
    mFirstGroupBulletFirstPaintFarR = 25,
    mFirstGroupBulletFirstPaintFarRate = 1,
    mFirstGroupBulletSecondAfterPaintNearD = 50,
    mFirstGroupBulletSecondAfterPaintNearR = 0,
    mFirstGroupBulletSecondAfterPaintNearRate = 1,
    mFirstGroupBulletSecondAfterPaintFarD = 150,
    mFirstGroupBulletSecondAfterPaintFarR = 0,
    mFirstGroupBulletSecondAfterPaintFarRate = 1,
    mFirstGroupBulletFirstCollisionRadiusForField = 7,
    mFirstGroupBulletAfterCollisionRadiusForFieldOffset = 0,
    mFirstGroupBulletFirstCollisionRadiusForPlayer = 9,
    mFirstGroupBulletAfterCollisionRadiusForPlayerOffset = 0,
    mFirstGroupBulletFirstDamageMaxValue = 0.62,
    mFirstGroupBulletFirstDamageMinValue = 0.3,
    mFirstGroupBulletDamageRateBias = 1,
    mFirstGroupBulletAfterDamageRateOffset = 0,
    mFirstGroupSplashFirstOccur = true,
    mFirstGroupSplashFromSecondToLastOneOccur = false,
    mFirstGroupSplashLastOccur = false,
    mFirstGroupSplashMaxNum = 3,
    mFirstGroupSplashDrawRadius = 3,
    mFirstGroupSplashColRadius = 1.5,
    mFirstGroupSplashPaintRadius = 8,
    mFirstGroupSplashDepthScaleRateByWidth = 1.5,
    mFirstGroupSplashBetween = 1000,
    mFirstGroupSplashFirstDropRandomRateMin = 1,
    mFirstGroupSplashFirstDropRandomRateMax = 1,
    mFirstGroupBulletUnuseOneEmitterBulletNum = 1,
    mFirstGroupCenterLine = true,
    mFirstGroupSideLine = false,

    mSecondGroupBulletNum = 3,
    mSecondGroupBulletFirstInitSpeedBase = 10,
    mSecondGroupBulletFirstInitSpeedJumpingBase = 8.6,
    mSecondGroupBulletAfterInitSpeedOffset = -3,
    mSecondGroupBulletInitSpeedRandomZ = 0,
    mSecondGroupBulletInitSpeedRandomX = 0,
    mSecondGroupBulletInitVecYRate = 0.1,
    mSecondGroupBulletFirstDrawRadius = 8,
    mSecondGroupBulletAfterDrawRadiusOffset = -1,
    mSecondGroupBulletFirstPaintNearD = 50,
    mSecondGroupBulletFirstPaintNearR = 14,
    mSecondGroupBulletFirstPaintNearRate = 1.5,
    mSecondGroupBulletFirstPaintFarD = 85,
    mSecondGroupBulletFirstPaintFarR = 12,
    mSecondGroupBulletFirstPaintFarRate = 1.7,
    mSecondGroupBulletSecondAfterPaintNearD = 31,
    mSecondGroupBulletSecondAfterPaintNearR = 8,
    mSecondGroupBulletSecondAfterPaintNearRate = 2.2,
    mSecondGroupBulletSecondAfterPaintFarD = 58,
    mSecondGroupBulletSecondAfterPaintFarR = 9,
    mSecondGroupBulletSecondAfterPaintFarRate = 1.9,
    mSecondGroupBulletFirstCollisionRadiusForField = 7,
    mSecondGroupBulletAfterCollisionRadiusForFieldOffset = -1,
    mSecondGroupBulletFirstCollisionRadiusForPlayer = 8,
    mSecondGroupBulletAfterCollisionRadiusForPlayerOffset = -1,
    mSecondGroupBulletFirstDamageMaxValue = 0.62,
    mSecondGroupBulletFirstDamageMinValue = 0.3,
    mSecondGroupBulletDamageRateBias = 1,
    mSecondGroupBulletAfterDamageRateOffset = 0,
    mSecondGroupSplashFirstOccur = false,
    mSecondGroupSplashFromSecondToLastOneOccur = false,
    mSecondGroupSplashLastOccur = true,
    mSecondGroupSplashMaxNum = 1,
    mSecondGroupSplashDrawRadius = 2,
    mSecondGroupSplashColRadius = 1.5,
    mSecondGroupSplashPaintRadius = 7,
    mSecondGroupSplashDepthScaleRateByWidth = 2.8,
    mSecondGroupSplashBetween = 25,
    mSecondGroupSplashFirstDropRandomRateMin = 1,
    mSecondGroupSplashFirstDropRandomRateMax = 1,
    mSecondGroupBulletUnuseOneEmitterBulletNum = 0,
    mSecondGroupCenterLine = true,
    mSecondGroupSideLine = false,

    mThirdGroupBulletNum = 1,
    mThirdGroupBulletFirstInitSpeedBase = 9.5,
    mThirdGroupBulletFirstInitSpeedJumpingBase = 8,
    mThirdGroupBulletAfterInitSpeedOffset = -2,
    mThirdGroupBulletInitSpeedRandomZ = 0,
    mThirdGroupBulletInitSpeedRandomX = 0,
    mThirdGroupBulletInitVecYRate = 0.1,
    mThirdGroupBulletFirstDrawRadius = 10,
    mThirdGroupBulletAfterDrawRadiusOffset = 0,
    mThirdGroupBulletFirstPaintNearD = 50,
    mThirdGroupBulletFirstPaintNearR = 14,
    mThirdGroupBulletFirstPaintNearRate = 1.2,
    mThirdGroupBulletFirstPaintFarD = 80,
    mThirdGroupBulletFirstPaintFarR = 14,
    mThirdGroupBulletFirstPaintFarRate = 1.2,
    mThirdGroupBulletSecondAfterPaintNearD = 50,
    mThirdGroupBulletSecondAfterPaintNearR = 8.5,
    mThirdGroupBulletSecondAfterPaintNearRate = 1.6,
    mThirdGroupBulletSecondAfterPaintFarD = 80,
    mThirdGroupBulletSecondAfterPaintFarR = 8.5,
    mThirdGroupBulletSecondAfterPaintFarRate = 1.6,
    mThirdGroupBulletFirstCollisionRadiusForField = 5,
    mThirdGroupBulletAfterCollisionRadiusForFieldOffset = 0,
    mThirdGroupBulletFirstCollisionRadiusForPlayer = 7,
    mThirdGroupBulletAfterCollisionRadiusForPlayerOffset = 0,
    mThirdGroupBulletFirstDamageMaxValue = 0.62,
    mThirdGroupBulletFirstDamageMinValue = 0.3,
    mThirdGroupBulletDamageRateBias = 1,
    mThirdGroupBulletAfterDamageRateOffset = 0,
    mThirdGroupSplashFirstOccur = true,
    mThirdGroupSplashFromSecondToLastOneOccur = false,
    mThirdGroupSplashLastOccur = false,
    mThirdGroupSplashMaxNum = 1,
    mThirdGroupSplashDrawRadius = 3,
    mThirdGroupSplashColRadius = 1.5,
    mThirdGroupSplashPaintRadius = 6.5,
    mThirdGroupSplashDepthScaleRateByWidth = 1.9,
    mThirdGroupSplashBetween = 63,
    mThirdGroupSplashFirstDropRandomRateMin = 0.5,
    mThirdGroupSplashFirstDropRandomRateMax = 1,
    mThirdGroupBulletUnuseOneEmitterBulletNum = 1,
    mThirdGroupCenterLine = false,
    mThirdGroupSideLine = true,

    mFirstGroupBulletAfterFrameOffset = 0,
    mSecondGroupBulletFirstFrameOffset = 2,
    mSecondGroupBulletAfterFrameOffset = 2,
    mThirdGroupBulletFirstFrameOffset = 3,
    mThirdGroupBulletAfterFrameOffset = 0,

    mFrameOffsetMaxMoveLength = 5,
    mFrameOffsetMaxDegree = 1.5,
    mLineNum = 3,
    mLineDegree = 30,
    mGuideCenterGroup = 1,
    mGuideCenterBulletNumInGroup = 1,
    mGuideCenterCheckCollisionFrame = 13,
    mGuideSideGroup = 0,
    mGuideSideBulletNumInGroup = 1,
    mGuideSideCheckCollisionFrame = 8,
    mShotRandomDegreeExceptBulletForGuide = 3,
    mShotRandomBiasExceptBulletForGuide = 0.5,

    mFreeStateGravity = 0.5,
    mFreeStateAirResist = 0.12,

    mDropSplashDrawRadius = 2,
    mDropSplashColRadius = 2,
    mDropSplashPaintRadius = 7.5,
    mDropSplashPaintRate = 2,
    mDropSplashOffsetX = 2,
    mDropSplashOffsetZ = -7,
    mTailSolidFrame = 5,
    mTailMaxLength = 20,
    mTailMinLength = 5,

    mSpiralSplashGroup = 0,
    mSpiralSplashBulletNumInGroup = 1,
    mSpiralSplashInitSpeed = 5,
    mSpiralSplashSpeedBaseDist = -15,
    mSpiralSplashSpeedMaxDist = -85,
    mSpiralSplashSpeedMaxRate = 1,
    mSpiralSplashLifeFrame = 7,
    mSpiralSplashMinSpanFrame = 1,
    mSpiralSplashMinSpanBulletCounter = 40,
    mSpiralSplashMaxSpanFrame = 1,
    mSpiralSplashMaxSpanBulletCounter = 1,
    mSpiralSplashSameTimeBulletNum = 2,
    mSpiralSplashRoundSplitNum = 8,
    mSpiralSplashColRadiusForField = 3,
    mSpiralSplashColRadiusForPlayer = 3,
    mSpiralSplashMaxDamage = 0.6,
    mSpiralSplashMinDamage = 0.2,
    mSpiralSplashMaxDamageDist = 10,
    mSpiralSplashMinDamageDist = 40,

    mScatterSplashGroup = 0,
    mScatterSplashBulletNumInGroup = 1,
    mScatterSplashInitSpeed = 5,
    mScatterSplashMinSpanBulletCounter = 1,
    mScatterSplashMinSpanFrame = 1,
    mScatterSplashMaxSpanBulletCounter = 1,
    mScatterSplashMaxSpanFrame = 2,
    mScatterSplashMaxNum = 25,
    mScatterSplashUpDegree = 60,
    mScatterSplashDownDegree = 70,
    mScatterSplashDegreeBias = 0.5,
    mScatterSplashColRadius = 3,
    mScatterSplashPaintRadius = 6,
    mScatterSplashInitPosMinOffset = 2,
    mScatterSplashInitPosMaxOffset = 15,

    mInkConsume = 0.06,
    mInkRecoverStop = 35,
    mMoveSpeed = 0.7,
    mBulletStraightFrame = 3,
    mBulletPaintBaseDist = -15,
    mBulletPaintMaxDist = -85,
    mBulletPaintMaxRate = 0.9,
    mPaintTextureCenterOffsetRate = 0,
    mBulletDamageMaxDist = -15,
    mBulletDamageMinDist = -85,
    mBulletCollisionRadiusForPlayerInitRate = 0.1,
    mBulletCollisionRadiusForPlayerSwellFrame = 5,
    mBulletCollisionPlayerSameTeamNotHitFrame = 2,
    mBulletCollisionRadiusForFieldInitRate = 0.1,
    mBulletCollisionRadiusForFieldSwellFrame = 4,
    mHitWallSplashOnlyCenter = false,
    mHitWallSplashFirstLength = 22,
    mHitWallSplashBetweenLength = 15,
    mHitWallSplashMinusYRate = 0.45,
    mHitWallSplashDistanceRate = 1.3333,

    mHitPlayerDrapDrawRadius = 6,
    mHitPlayerDrapCollisionRadius = 4,
    mHitPlayerDrapPaintRadiusRate = 0,
    mHitPlayerDrapHitPlayerOffset = 10,
    mHitPlayerDrapHitObjectOffset = 0,
    mPostDelayFrm_Main = 5,
})
