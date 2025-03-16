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
end

function StoreImpl.GetStore(
	storeId: string
): Store
	if StoreIdSpace[storeId] then
		return StoreIdSpace[storeId]
	end
	
	local self = {}
	
	self._id = storeId
	self._self = {}
	self._registeredTables = {}
	self._observeFunctions = {}
	
	self = setmetatable(self, StoreImpl)
	
	StoreIdSpace[storeId] = self
	
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

return StoreImpl