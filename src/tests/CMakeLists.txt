# Boostを探す
#find_package(Boost REQUIRED COMPONENTS unit_test_framework)

# テスト実行ファイルを作成
add_executable(feature1_test feature1_test.cpp)

# テスト実行ファイルにライブラリをリンク
# target_link_libraries(feature1_test
#     Boost::unit_test_framework
#     # 他の必要なライブラリもここに追加
# )

# テストを登録
add_test(NAME Feature1Test COMMAND feature1_test)
