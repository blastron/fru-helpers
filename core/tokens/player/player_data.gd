class_name PlayerData extends RefCounted

signal role_changed()

# The player's job. Used to automatically determine role.
enum Job {
	PLD, WAR, DRK, GNB,
	WHM, AST, SCH, SGE,
	MNK, DRG, NIN, SAM, RPR, VPR,
	BRD, MCH, DNC,
	BLM, SMN, RDM, PCT
}
var job: Job = Job.BRD :
	get: return job
	set(value):
		job = value
		role_changed.emit()

# The group (or, "light party") that this player belongs to.
enum Group { GROUP_ONE, GROUP_TWO }
var group: Group = Group.GROUP_ONE :
	get:
		return group
	set(value):
		group = value
		role_changed.emit()

# Whether or not the user controls this player. Assumed to be true for only one player at a time.
var user_controlled: bool = false :
	get: return user_controlled
	set(value):
		user_controlled = value
		role_changed.emit()

# Force a player into a specific role spot, ignoring their job. Use when you're running double phys ranged because your
#   PCT is carrying the entire DPS meter on their back.
# Set to Role.NONE if no fake role is assigned.
var fake_role: Role = Role.NONE :
	get: return fake_role
	set(value):
		fake_role = value
		role_changed.emit()

enum Role {
	NONE,
	TANK, MAIN_TANK, OFF_TANK,
	HEALER, PURE_HEALER, BARRIER_HEALER,
	MELEE,
	RANGED, PHYS_RANGED, CASTER
}

var role: Role :
	get: return get_role_for_job(job)
	set(value):
		assert(false, "Don't set role directly. Use job or fake_role instead.")
		fake_role = value

var detailed_role: Role :
	get:
		if fake_role == Role.NONE:
			var matched_role: Role = get_detailed_role_for_job(job)
			if matched_role == Role.TANK:
				return Role.MAIN_TANK if group == Group.GROUP_ONE else Role.OFF_TANK
			else: return matched_role
		else:
			return fake_role
	set(value):
		assert(false, "Don't set detailed_role directly. Use job or fake_role instead.")
		fake_role = value

func _init(in_job: Job, in_group: Group):
	job = in_job
	group = in_group

# Gets the name for a given job.
# TODO: Move this to a string table in case this winds up needing localization
static func get_job_name(job: Job) -> String:
	match job:
		Job.PLD: return "Paladin"
		Job.WAR: return "Warrior"
		Job.DRK: return "Dark Knight"
		Job.GNB: return "Gunbreaker"
		Job.WHM: return "White Mage"
		Job.AST: return "Astrologian"
		Job.SCH: return "Scholar"
		Job.SGE: return "Sage"
		Job.MNK: return "Monk"
		Job.DRG: return "Dragoon"
		Job.NIN: return "Ninja"
		Job.SAM: return "Samurai"
		Job.RPR: return "Reaper"
		Job.VPR: return "Viper"
		Job.BRD: return "Bard"
		Job.MCH: return "Machinist"
		Job.DNC: return "Dancer"
		Job.BLM: return "Black Mage"
		Job.SMN: return "Summoner"
		Job.RDM: return "Red Mage"
		Job.PCT: return "Pictomancer"
	return "Unknown"

# Gets the jobs matching a role.
static func get_jobs_for_role(role: Role) -> Array[Job]:
	match role:
		Role.TANK, Role.MAIN_TANK, Role.OFF_TANK: return [Job.PLD, Job.WAR, Job.DRK, Job.GNB]
		Role.HEALER: return [Job.WHM, Job.AST, Job.SCH, Job.SGE]
		Role.PURE_HEALER: return [Job.WHM, Job.AST]
		Role.BARRIER_HEALER: return [Job.SCH, Job.SGE]
		Role.MELEE: return [Job.MNK, Job.DRG, Job.NIN, Job.SAM, Job.RPR, Job.VPR]
		Role.RANGED: return [Job.BRD, Job.MCH, Job.DNC, Job.BLM, Job.SMN, Job.RDM, Job.PCT]
		Role.PHYS_RANGED: return [Job.BRD, Job.MCH, Job.DNC]
		Role.CASTER: return [Job.BLM, Job.SMN, Job.RDM, Job.PCT]
		_: return []
		
static func get_role_for_job(job: Job) -> Role:
	return simplify_detailed_role(get_detailed_role_for_job(job))
	
static func get_detailed_role_for_job(job: Job) -> Role:
	match job:
		Job.PLD, Job.WAR, Job.DRK, Job.GNB:
			return Role.TANK
		Job.WHM, Job.AST:
			return Role.PURE_HEALER
		Job.SCH, Job.SGE:
			return Role.BARRIER_HEALER
		Job.MNK, Job.DRG, Job.NIN, Job.SAM, Job.RPR, Job.VPR:
			return Role.MELEE
		Job.BRD, Job.MCH, Job.DNC:
			return Role.PHYS_RANGED
		Job.BLM, Job.SMN, Job.RDM, Job.PCT:
			return Role.CASTER
		_:
			return Role.NONE

# Takes a detailed role (e.g. "pure healer") and turns it into a general role (e.g. "healer")
static func simplify_detailed_role(detailed_role: Role) -> Role:
	match detailed_role:
		Role.TANK, Role.MAIN_TANK, Role.OFF_TANK:
			return Role.TANK
		Role.HEALER, Role.PURE_HEALER, Role.BARRIER_HEALER:
			return Role.HEALER
		Role.MELEE:
			return Role.MELEE
		Role.RANGED, Role.PHYS_RANGED, Role.CASTER:
			return Role.RANGED
		_:
			return Role.NONE
