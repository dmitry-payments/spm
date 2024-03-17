pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract AtomicSwapIERC20 {

    // Адрес владельца контракта
    address public owner;

    // Мапа для хранения информации о полученных деньгах
    mapping(address => uint256) public receivedAmounts;

    // Мапа для хранения информации о приоритетных адресах для выплат
    mapping(address => uint256) public priorityAddresses;

    // Награда контракта
    uint256 contractRevenue;

    // Общая сумма контракта
    uint256 totalAmount;

    // Конструктор контракта
    constructor() {
        // Устанавливаем владельца контракта на адрес того, кто развернул контракт
        owner = msg.sender;
    }

    // Функция, позволяющая контракту принимать деньги
    receive() external payable {
        // Записываем в мапу отправителя и сумму
        receivedAmounts[msg.sender] = msg.value;
        totalAmount += msg.value;
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

            // Получаем сумму первого отправителя в мапе
            uint256 previousAmount = receivedAmounts[previousAddress];

            // Проверяем условие если сумма следующего сендера больше или равна предыдущего
            if (previousAmount <= lastSenderAmount && previousAmount != 0) {

                // Сначала проверяем нет ли приоритентных адресов для выплат
                findPriorityAddress();

                // Рассчитываем сумму для отправки, добавляя 80% к previousAmount
                uint256 amountToSend = previousAmount + (previousAmount * 80 / 100);

                contractRevenue = previousAmount * 20 / 100;

                // Отправляем эфир на адрес предыдущего отправителя
                payable(previousAddress).transfer(amountToSend);

                //Делаем неактивным адрес предыдущего отправителя
                receivedAmounts[previousAddress] = 0;
            }

            // Проверяем условие если сумма следующего сендера меньше предыдущего, но общая сумма контракта позволяет сделать выплату
            if (previousAmount > lastSenderAmount && totalAmount >= previousAmount * 2) {

                // Сначала проверяем нет ли приоритентных адресов для выплат
                findPriorityAddress();

                // Рассчитываем сумму для отправки, добавляя 80% к previousAmount
                uint256 amountToSend = previousAmount + (previousAmount * 80 / 100);

                contractRevenue = previousAmount * 20 / 100

                // Отправляем эфир на адрес предыдущего отправителя
                payable(previousAddress).transfer(amountToSend);

                //Делаем неактивным адрес предыдущего отправителя
                receivedAmounts[previousAddress] = 0;
            }

            // Проверяем условие если сумма следующего сендера меньше предыдущего, но общая сумма контракта НЕ позволяет сделать выплату
            if (previousAmount > lastSenderAmount && totalAmount < previousAmount) {

                // Добавляем адрес в приоритетную мапу для первостепенных выплат
                priorityAddresses[previousAddress] = previousAmount;
            }
        }
    }

    function findPriorityAddress() {
        // Проверяем есть ли приоритетные адреса для выплат
        if (priorityAddresses.length > 0) {
            // Проходим по мапе приоритетных адресов
            for (address priorityAddress : priorityAddresses) {
                // Проверяем что общая сумма достаточна для выплаты приоритетному сендеру и награды контракта и что сендер активный
                if (totalAmount >= priorityAddresses[priorityAddress] * 2 && priorityAddresses[priorityAddress] != 0) {
                    // Сумма выплаты
                    uint256 amountToSend = priorityAddresses[priorityAddress] + (priorityAddresses[priorityAddress] * 80 / 100);
                    // Награда контракту
                    contractRevenue = priorityAddresses[priorityAddress] * 20 / 100;
                    // Отправляем эфир
                    payable(priorityAddress).transfer(amountToSend);
                    // Делаем неактивным адрес приоритетного отправителя
                    priorityAddresses[priorityAddress] = 0;
                }
            }
        } 
    }
}
