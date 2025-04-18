--!strict
--!optimize 2

--#[ Types ]#--
export type StoreImpl = {
	__index: (
		self: Store,
		key: string
	) -> any;
	__newindex: (
		self: Store,
		key: string,
		value: any
	) -> ();

	GetStore: (
		storeId: string
	) -> Store;
}

export type Store = typeof(setmetatable({} :: {
	_id: string?;
	_self: { [string]: any };
	_registeredTables: {
		[string]: {
			{
				targetTable: { [any]: any };
				targetKey: string?;
			}
		}
	};
	_observeFunctions: {
		[string]: {
			(
				newValue: any,
				oldValue: any
			) -> ()
		}
	};
	_asyncObserveFunctions: {
		[string]: {
			(
				newValue: any,
				oldValue: any
			) -> ()
		}
	};
	_asyncObserveAllFunctions: {
		(
			storeKey: string,
			newValue: any,
			oldValue: any
		) -> ()
	};
	_waitThreads: {
		[string]: {
			{
				thread: thread;
				value: any?;
				isSimple: boolean?;
			}
		}
	};
	_tweens: {
		[string]: {
			tween: Tween;
			valueInstance: NumberValue | Vector3Value | CFrameValue | Color3Value;
		}
	};

	Register: (
		self: Store,
		storeKey: string,
		targetTable: { [any]: any },
		targetKey: string?
	) -> Store;
	Unregister: (
		self: Store,
		storeKey: string,
		targetTable: { [any]: any },
		targetKey: string?
	) -> Store;
	Observe: (
		self: Store,
		storeKey: string,
		observeFunction: (
			newValue: any,
			oldValue: any
		) -> ()
	) -> Store;
	ObserveAsync: (
		self: Store,
		storeKey: string,
		observeFunction: (
			newValue: any,
			oldValue: any
		) -> ()
	) -> Store;
	ObserveAll: (
		self: Store,
		observeFunction: (
			storeKey: string,
			newValue: any,
			oldValue: any
		) -> ()
	) -> Store;
	ObserveAllAsync: (
		self: Store,
		observeFunction: (
			storeKey: string,
			newValue: any,
			oldValue: any
		) -> ()
	) -> Store;
	Trigger: (
		self: Store,
		storeKey: string,
		alsoTriggerObserveAll: boolean?
	) -> Store;
	WaitForChange: (
		self: Store,
		storeKey: string
	) -> (any, any);
	WaitForValue: <T>(
		self: Store,
		storeKey: string,
		value: T
	) -> (T, any);
	Tween: (
		self: Store,
		storeKey: string,
		tweenInfo: TweenInfo,
		goal: any
	) -> Store;
}, {} :: StoreImpl))

--#[ Services ]#--
local TweenService = game:GetService("TweenService")

--#[ Head Variables ]#--
local StoreIdSpace = {}

local StoreImpl = {} :: StoreImpl
local Methods = {}

--#[ Modules ]#--
--

--#[ Variables ]#--
--

--#[ Functions ]#--
--

--#[ Main ]#--
function StoreImpl.__index(
	self: Store,
	key: string
): any
	if Methods[key] then
		return Methods[key]
	end

	return self._self[key]
end

function StoreImpl.__newindex(
	self: Store,
	key: string,
	value: any
)
	if Methods[key] then
		error("메서드를 재정의 할 수 없습니다.")
	end

	local oldValue = self._self[key]

	if oldValue == value then
		return
	end

	self._self[key] = value

	if self._registeredTables[key] then
		for _, v in self._registeredTables[key] do
			v.targetTable[v.targetKey or key] = value
		end
	end
	
	if self._observeFunctions[key] then
		for _, v in self._observeFunctions[key] do
			v(value, oldValue)
		end
	end

	if self._asyncObserveFunctions[key] then
		for _, v in self._asyncObserveFunctions[key] do
			task.spawn(v, value, oldValue)
		end
	end

	for _, v in self._observeAllFunctions do
		v(key, value, oldValue)
	end
	
	for _, v in self._asyncObserveAllFunctions do
		task.spawn(v, key, value, oldValue)
	end

	if self._waitThreads[key] then
		local index = 1

		while true do
			if index > #self._waitThreads[key] then
				break
			end

			local _value = self._waitThreads[key][index]

			if _value.isSimple or (not _value.isSimple and _value.value == value) then
				task.spawn(_value.thread, value, oldValue)

				table.remove(self._waitThreads[key], index)
			else
				index += 1
			end
		end
	end
end

function StoreImpl.GetStore(
	storeId: string?
): Store
	if storeId and  StoreIdSpace[storeId] then
		return StoreIdSpace[storeId]
	end

	local self = {}

	self._id = storeId
	self._self = {}
	self._registeredTables = {}
	self._observeFunctions = {}
	self._asyncObserveFunctions = {}
	self._observeAllFunctions = {}
	self._asyncObserveAllFunctions = {}
	self._waitThreads = {}
	self._tweens = {}

	self = setmetatable(self, StoreImpl)

	if storeId then
		StoreIdSpace[storeId] = self
	end

	return (self :: any) :: Store
end

function Methods:Register(
	storeKey: string,
	targetTable: { [any]: any },
	targetKey: string?
): Store
	self._registeredTables[storeKey] = self._registeredTables[storeKey] or {}
	table.insert(self._registeredTables[storeKey], {
		targetTable = targetTable;
		targetKey = targetKey;
	})

	return self
end

function Methods:Unregister(
	storeKey: string,
	targetTable: { [any]: any },
	targetKey: string?
): Store
	if self._registeredTables[storeKey] then
		for index, value in self._registeredTables[storeKey] do
			if value.targetTable == targetTable and value.targetKey == targetKey then
				table.remove(self._registeredTables[storeKey], index)

				break
			end
		end
	end

	return self
end

function Methods:Observe(
	storeKey: string,
	observeFunction: (
		newValue: any,
		oldValue: any
	) -> ()
): Store
	self._observeFunctions[storeKey] = self._observeFunctions[storeKey] or {}
	table.insert(self._observeFunctions[storeKey], observeFunction)

	return self
end

function Methods:ObserveAsync(
	storeKey: string,
	observeFunction: (
		newValue: any,
		oldValue: any
	) -> ()
): Store
	
	self._asyncObserveFunctions[storeKey] = self._observeFunctions[storeKey] or {}
	table.insert(self._asyncObserveFunctions[storeKey], observeFunction)

	return self
end

function Methods:ObserveAll(
	observeFunction: (
		storeKey: string,
		newValue: any,
		oldValue: any
	) -> ()
)
	table.insert(self._observeAllFunctions, observeFunction)

	return self
end

function Methods:ObserveAllAsync(
	observeFunction: (
		storeKey: string,
		newValue: any,
		oldValue: any
	) -> ()
)
	table.insert(self._asyncObserveAllFunctions, observeFunction)

	return self
end

function Methods:Trigger(
	storeKey: string,
	alsoTriggerObserveAll: boolean?
): Store
	if self._observeFunctions[storeKey] then
		for _, v in self._observeFunctions[storeKey] do
			task.spawn(v)
		end
	end

	for _, v in self._observeAllFunctions do
		task.spawn(v)
	end

	return self
end

function Methods:WaitForChange(
	storeKey: string
): (any, any)
	local thread = coroutine.running()

	self._waitThreads[storeKey] = self._waitThreads[storeKey] or {}
	table.insert(self._waitThreads[storeKey], {
		thread = thread;
		isSimple = true;
	})

	return coroutine.yield()
end

function Methods:WaitForValue<T>(
	storeKey: string,
	value: T
): (T, any)
	local thread = coroutine.running()

	self._waitThreads[storeKey] = self._waitThreads[storeKey] or {}
	table.insert(self._waitThreads[storeKey], {
		thread = thread;
		value = value;
	})

	return coroutine.yield()
end

function Methods:Tween(
	storeKey: string,
	tweenInfo: TweenInfo,
	goal: any
): Store
	if self._tweens[storeKey] then
		self._tweens[storeKey].tween:Destroy()
		self._tweens[storeKey].valueInstance:Destroy()
	end

	local valueInstance = if type(goal) == "number"
		then Instance.new("NumberValue") elseif typeof(goal) == "Vector3"
		then Instance.new("Vector3Value") elseif typeof(goal) == "CFrame"
		then Instance.new("CFrameValue") elseif typeof(goal) == "Color3"
		then Instance.new("Color3Value") else error("Store:Tween()이 지원하지 않는 타입의 목표입니다."); -- because of the fucking damn Roblox's type checker
	(valueInstance :: any).Value = goal
	local tween = TweenService:Create(
		valueInstance,
		tweenInfo,
		{ Value = goal }
	)

	self._tweens[storeKey] = self._tweens[storeKey] or {
		tween = tween;
		valueInstance = valueInstance;
	}

	(valueInstance :: NumberValue).Changed:Connect(function()
		StoreImpl.__newindex(self, storeKey, valueInstance.Value)
	end)
	tween:Play()
	warn("AAAAAAAAAAAAAA")

	return self
end

return StoreImpl