local P = {}
local Extram = require('Extram')

P.caches = {}

P.key = nil
P.c = nil

-- message: メッセージ本文
-- mode: 動作モード 0 = 常に最新データを使う / 1 = キャッシュを使う
function P.mes(message, mode)
    message = message:gsub("([\128-\160\224-\255]\092)\092","%1")
    P.key = "CacheText:" .. obj.layer .. "_" .. message
    if mode == 0 then
        Extram.del(P.key)
        P.caches[P.key] = nil
    end
    P.c = P.caches[P.key]
    if P.c == nil then
        mes(message)
    end
end

function P.after()
    if P.key == nil then
        -- 呼び出しがなんかおかしかった
        return
    end
    obj.cx = 0
    obj.cy = 0

    if P.c == nil then
        -- テキストオブジェクトで描画されたのでキャッシュに保存する
        local data, w, h = obj.getpixeldata()
        Extram.put(P.key, data, w * 4 * h)
        P.caches[P.key] = {
            t = os.clock(),
            w = w,
            h = h,
        }
    else
        -- 描画されなかったのでキャッシュから表示
        obj.setoption("drawtarget", "tempbuffer", P.c.w, P.c.h)
        obj.load("tempbuffer")
        local data, w, h = obj.getpixeldata()
        if not pcall(Extram.get, P.key, data, w * 4 * h) then
            -- キャッシュからの読み込みに失敗した場合は諦める（手動で消された場合など）
            P.caches[P.key] = nil
            P.c = nil
            P.key = nil
            return
        end
        obj.putpixeldata(data)
        P.c.t = os.clock()
        P.caches[P.key] = P.c
    end

    P.key = nil
    P.c = nil

    -- 不要なデータの掃除
    P.gc()
end

P.lifetime = 3 -- 秒
P.gcinterval = 10 -- 秒
P.lastgc = 0
function P.gc()
    local t = os.clock()
    if P.lastgc + P.gcinterval >= t then
        -- まだあんまり時間が経ってない
        return
    end
    for key, c in pairs(P.caches) do
        if c.t + P.lifetime < t then
            -- 最近使われていないので削除
            Extram.del(key)
            P.caches[key] = nil
        end
    end
    P.lastgc = os.clock()
end

return P