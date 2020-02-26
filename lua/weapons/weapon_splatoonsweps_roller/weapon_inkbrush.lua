
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.SplashSound = "SplatoonSWEPs.RollerSplashLight"
SWEP.RollSoundName = ss.InkBrushRun
SWEP.Special = "inkstrike"
SWEP.Sub = "sprinkler"
SWEP.Variations = {
	{
		Customized = true,
		Skin = 1,
		Special = "bubbler",
		Sub = "inkmine",
		Suffix = "nouveau",
	},
	{
		SheldonsPicks = true,
		Skin = 2,
		Special = "kraken",
		Sub = "splatbomb",
		Suffix = "permanent",
	},
}

ss.SetPrimary(SWEP, {
	mSwingLiftFrame = 1,
	mSplashNum = 2,
	mSplashInitSpeedBase = 5.5,
	mSplashInitSpeedRandomZ = 1,
	mSplashInitSpeedRandomX = 0.8,
	mSplashInitVecYRate = -0.02,
	mSplashDeg = 1.5,
	mSplashSubNum = 1,
	mSplashSubInitSpeedBase = 3.2,
	mSplashSubInitSpeedRandomZ = 0.8,
	mSplashSubInitSpeedRandomX = 1.2,
	mSplashSubInitVecYRate = -0.02,
	mSplashSubDeg = 1.5,
	mSplashPositionWidth = 1,
	mSplashInsideDamageRate = 1,
	mCorePaintWidthHalf = 6,
	mCorePaintSlowMoveWidthHalf = 6,
	mSlowMoveSpeed = 1.2,
	mCoreColWidthHalf = 4,
	mInkConsumeCore = 0.0015,
	mInkConsumeSplash = 0.02,
	mInkRecoverCoreStop = 20,
	mInkRecoverSplashStop = 30,
	mMoveSpeed = 1.92,
	mCoreColRadius = 4,
	mCoreDamage = 0.2,
	mTargetEffectScale = 1.2,
	mTargetEffectVelRate = 0.7,
	mSplashStraightFrame = 5,
	mSplashDamageMaxDist = 50,
	mSplashDamageMinDist = 100,
	mSplashDamageMaxValue = 0.28,
	mSplashDamageMinValue = 0.14,
	mSplashOutsideDamageMaxDist = 10,
	mSplashOutsideDamageMinDist = 80,
	mSplashOutsideDamageMaxValue = 1.4,
	mSplashOutsideDamageMinValue = 0.3,
	mSplashDamageRateBias = 1,
	mSplashDrawRadius = 3.5,
	mSplashPaintNearD = 100,
	mSplashPaintNearR = 22,
	mSplashPaintFarD = 100,
	mSplashPaintFarR = 22,
	mSplashCollisionRadiusForField = 8,
	mSplashCollisionRadiusForPlayer = 12,
	mSplashCoverApertureFreeFrame = -1,
	mSplashSubStraightFrame = 3,
	mSplashSubDamageMaxDist = 50,
	mSplashSubDamageMinDist = 100,
	mSplashSubDamageMaxValue = 0.28,
	mSplashSubDamageMinValue = 0.14,
	mSplashSubDamageRateBias = 1,
	mSplashSubDrawRadius = 2,
	mSplashSubPaintNearD = 100,
	mSplashSubPaintNearR = 12,
	mSplashSubPaintFarD = 100,
	mSplashSubPaintFarR = 12,
	mSplashSubCollisionRadiusForField = 4,
	mSplashSubCollisionRadiusForPlayer = 6,
	mSplashSubCoverApertureFreeFrame = -1,
	mSplashPaintType = 1,
	mArmorTypeObjectDamageRate = 0.4,
	mArmorTypeGachihokoDamageRate = 0.5,
	mPaintBrushType = true,
	mPaintBrushRotYDegree = 10,
	mPaintBrushSwingRepeatFrame = 6,
	mPaintBrushNearestBulletLoopNum = 6,
	mPaintBrushNearestBulletOrderNum = 2,
	mPaintBrushNearestBulletRadius = 20,
	mDropSplashDrawRadius = 0.5,
	mDropSplashPaintRadius = 0,
})
