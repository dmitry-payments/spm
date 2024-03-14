pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract AtomicSwapIERC20 {

    // Адрес владельца контракта
    address public owner;

    // Мапа для хранения информации о полученных деньгах
    mapping(address => uint256) public receivedAmounts;

    // Награда контракта
    uint256 contractRevenue;

    // Конструктор контракта
    constructor() {
        // Устанавливаем владельца контракта на адрес того, кто развернул контракт
        owner = msg.sender;
    }

    // Функция, позволяющая контракту принимать деньги
    receive() external payable {
        // Записываем в мапу отправителя и сумму
        receivedAmounts[msg.sender] += msg.value;
        if (receivedAmounts.length > 0) {
            findAndSendRevenue(msg.sender);
        }
    }

    // Функция для поиска адресов отправителей и отправки награды
    function findAndSendRevenue(address sender) public {
        // Получаем сумму последнего отправителя
        uint256 lastSenderAmount = receivedAmounts[sender];

        // Проходим по мапе
        for (address previousAddress : receivedAmounts) {
            // Получаем сумму отправителя
            uint256 previousAmount = receivedAmounts[previousAddress];

            // Проверяем условие если сумма следующего сендера больше или равна предыдущего
            if (previousAmount <= lastSenderAmount) {

                // Рассчитываем сумму для отправки, добавляя 80% к previousAmount
                uint256 amountToSend = previousAmount + (previousAmount * 80 / 100);

                contractRevenue = previousAmount * 20 / 100

                // Отправляем эфир на адрес предыдущего отправителя
                payable(previousAddress).transfer(amountToSend);
            }

            // Проверяем условие если сумма следующего сендера меньше предыдущего
            if (previousAmount > lastSenderAmount) {

                // Рассчитываем сумму для отправки, добавляя 80% к previousAmount
                uint256 amountToSend = previousAmount + (previousAmount * 80 / 100);

                contractRevenue = previousAmount * 20 / 100

                // Отправляем эфир на адрес предыдущего отправителя
                payable(previousAddress).transfer(amountToSend);
            }
        }
    }
}
