scoreboard players add @a sbu_warning_age 1

execute as @a[scores={sbu_warning_age=40..}] unless score @s sbu_warning_shown matches 1 unless entity @s[advancements={shulker_box_uncrafting:internal/recipe_remainders_present=true}] run title @s title {"text":"Recipe Remainders required","color":"red","bold":true}
execute as @a[scores={sbu_warning_age=40..}] unless score @s sbu_warning_shown matches 1 unless entity @s[advancements={shulker_box_uncrafting:internal/recipe_remainders_present=true}] run title @s subtitle {"text":"Install it on the server to use this datapack.","color":"white"}
execute as @a[scores={sbu_warning_age=40..}] unless score @s sbu_warning_shown matches 1 unless entity @s[advancements={shulker_box_uncrafting:internal/recipe_remainders_present=true}] run tellraw @s {"text":"Shulker Box Uncrafting requires Recipe Remainders on this server.","color":"red"}
execute as @a[scores={sbu_warning_age=40..}] unless score @s sbu_warning_shown matches 1 unless entity @s[advancements={shulker_box_uncrafting:internal/recipe_remainders_present=true}] run scoreboard players set @s sbu_warning_shown 1
