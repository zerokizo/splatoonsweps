AddCSLuaFile()
return {Options = {
    AvoidWalls = "壁を避けて狙う",
    AvoidWalls_help = "インクが壁に吸われないようにする。",
    BecomeSquid = "イカになる",
    BecomeSquid_help = "しゃがみ時にイカになるか、屈んだヒトになるか。",
    CanDrown = "水没時に死ぬ",
    CanHealInk = "インク内でHP回復",
    CanHealInk_help = false,
    CanHealStand = "インク外でHP回復",
    CanHealStand_help = false,
    CanReloadInk = "インク内でインク回復",
    CanReloadInk_help = false,
    CanReloadStand = "インク外でインク回復",
    CanReloadStand_help = false,
    DoomStyle = "DOOMスタイル",
    DoomStyle_help = "一人称視点でブキが中央に配置される。",
    DrawCrosshair = "照準の描画",
    DrawInkOverlay = "インクオーバーレイの描画",
    DrawInkOverlay_help = "一人称視点でインクに潜った時、画面に水のエフェクトがかかる。",
    Enabled = "Splatoon SWEPsの有効化",
    ExplodeOnlySquids = "インクリングの撃破時に限り爆発する",
    ExplodeOnlySquids_help = [[チェックを入れると、スプラトゥーンのブキを持っている相手のみ撃破時に爆発するようになる。
チェックを外すと、スプラトゥーンのブキで倒した相手は必ず爆発する。]],
    FF = "同士討ちの有効化",
    Gain = {
        __printname = "各種パラメータ",
        HealSpeedInk = "体力回復速度[%] (インク内)",
        HealSpeedStand = "体力回復速度[%] (インク外)",
        MaxHealth = "最大ヘルス",
        InkAmount = "インクタンク容量",
        ReloadSpeedInk = "インク回復速度[%] (インク内)",
        ReloadSpeedStand = "インク回復速度[%] (インク外)",
    },
    HideInk = "マップ上のインクを非表示にする",
    HideInk_help = "チェックを入れると、マップ上に塗られたインクが非表示になる。",
    InkColor = "インクの色",
    LeftHand = "左利き",
    LeftHand_help = "一人称視点でブキが左側に表示される。",
    MoveViewmodel = "壁を避けて狙うとき、ビューモデルを動かす",
    MoveViewmodel_help = "「壁を避けて狙う」が有効のとき、一人称視点で腕が動く。",
    NewStyleCrosshair = "Splatoon 2風の照準",
    NPCInkColor = {
        __printname = "NPCのインクの色",
        Citizen = "市民",
        Combine = "コンバイン",
        Military = "「軍隊」に属するNPC",
        Zombie = "ゾンビ",
        Antlion = "アントライオン",
        Alien = "エイリアン",
        Barnacle = "バーナクル",
        Others = "その他",
    },
    TakeFallDamage = "落下ダメージを有効化",
    ToggleADS = "アイアンサイト切り替え",
    ToggleADS_help = "アイアンサイトを長押しで覗くか、切り替えて覗くか。",
	weapon_splatoonsweps_blaster_base = {
		HurtOwner = "自爆を有効化",
	},
    weapon_splatoonsweps_charger = {
        UseRTScope = "リアルなスコープを使う",
        UseRTScope_help = "チェックを入れると、スコープ付きチャージャーのスコープを実際に覗いているかのような見た目になる。三人称視点ではスコープを覗かなくなる。",
        weapon_splatoonsweps_herocharger = {
            Level = "ヒーローチャージャーのレベル",
        },
    },
    weapon_splatoonsweps_shooter = {
        NZAP_PistolStyle = "N-ZAP: ピストル風",
        NZAP_PistolStyle_help = "N-ZAP83、N-ZAP85、N-ZAP89において、一人称視点で拳銃の持ち方をする。",
        weapon_splatoonsweps_heroshot = {
            Level = "ヒーローシューターのレベル",
        },
        weapon_splatoonsweps_octoshot = {
            Advanced = "オクタシューター: 上級タコゾネス仕様",
            Advanced_help = "オクタシューターレプリカの一部の色が少し変わる。"
        },
    },
    weapon_splatoonsweps_slosher_base = {
        Automatic = "フルオート",
    },
	weapon_splatoonsweps_roller = {
        AutomaticBrush = "フデ: フルオート連打",
        AutomaticBrush_help = "攻撃キーを押し続けると自動で連打する。塗り進みはできなくなる。",
        DropAtFeet = "フデ: 足元を塗る",
        DropAtFeet_help = "連続で振り攻撃をした場合に、足元にもインクが塗られるようにする。",
		weapon_splatoonsweps_heroroller = {
            Level = "ヒーローローラーのレベル",
        },
	},
}}
