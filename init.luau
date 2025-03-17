--!strict
--!optimize 2

--#[ Types ]#--
export type StoreImpl = {
	__index: (
		self: Store,
		key: any
	) -> any;
	__newindex: (
		self: Store,
		key: any,
		value: any
	) -> ();
	
	GetStore: (
		storeId: string
	) -> Store;
}

export type Store = typeof(setmetatable({} :: {
	_id: string;
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
	_waitThreads: {
		[string]: {
			thread: thread;
			value: any?;
			isSimple: boolean?;
		}
	}

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
	WaitForChange: (
		self: Store,
		storeKey: string
	) -> any;
	WaitForValue: <Store, string, T>(
		self: Store,
		storeKey: string,
		value: T
	) -> T;
}, {} :: StoreImpl))

--#[ Services ]#--
--

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
	self,
	key
): any
	if Methods[key] then
		return Methods[key]
	end
	
	return self._self[key]
end

function StoreImpl.__newindex(
	self,
	key,
	value
)
	if Methods[key] then
		error("메서드를 재정의 할 수 없습니다.")
	end
	
	local oldValue = self._self[key]
	
	self._self[key] = value
	
	if self._registeredTables[key] then
		for _, v in self._registeredTables[key] do
			task.spawn(function()
				v.targetTable[v.targetKey or key] = value
			end)
		end
	end
	
	if self._observeFunctions[key] then
		for _, v in self._observeFunctions[key] do
			task.spawn(v, value, oldValue)
		end
	end

	if self._waitThreads[key] then
		for _, v in self._waitThreads[key] do
			if v.isSimple or(not v.isSimple and v.value == value) then
				task.spawn(v.thread, value)
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
	self._waitThreads = {}
	
	self = setmetatable(self, StoreImpl)
	
	if storeId then
		StoreIdSpace[storeId] = self
	end
	
	return self :: Store
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

function Methods:WaitForChange(
	storeKey: string
): any
	local thread = coroutine.running()

	self._waitThreads[storeKey] = self._waitThreads[storeKey] or {}
	table.insert(self._waitThreads, {
		thread = thread;
		isSimple = true;
	})

	return coroutine.yield()
end

function Methods:<Store, string, T>WaitForValue(
	storeKey: string,
	value: T
): T
	local thread = coroutine.running()

	self._waitThreads[storeKey] = self._waitThreads[storeKey] or {}
	table.insert(self._waitThreads[storeKey], {
		thread = thread;
		value = value;
	})

	return coroutine.yield()
end

return StoreImpl
